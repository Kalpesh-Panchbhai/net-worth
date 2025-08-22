import Foundation
import SwiftUI
import Combine

@MainActor
final class AccountsController: ObservableObject {
    @Published var items: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    let userId: Int
    private let client: RestClient
    private var store: LookupStore? = nil
    private var cancellables = Set<AnyCancellable>()

    init(userId: Int, service: RestClient = RestClient()) {
        self.userId = userId
        self.client = service
    }

    func attachStore(_ store: LookupStore) {
        guard self.store == nil else { return }
        self.store = store
        store.$accounts
            .sink { [weak self] accounts in
                guard let self = self else { return }
                self.items = self.sortAccounts(accounts)
            }
            .store(in: &cancellables)
    }

    func load() async {
        if let store = store { // Use store-driven updates; trigger store load if empty
            self.items = sortAccounts(store.accounts)
            if store.accounts.isEmpty {
                isLoading = true
                errorMessage = nil
                defer { isLoading = false }
                await store.loadAccountsIfNeeded(userId: userId)
                self.items = sortAccounts(store.accounts)
            }
            return
        }
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await client.fetchAccounts(userId: userId)
            self.items = sortAccounts(fetched)
        } catch let api as APIError {
            // Suppress banners for user-initiated cancellations
            if case .transport(let err) = api, let urlErr = err as? URLError, urlErr.code == .cancelled {
                return
            }
            self.errorMessage = api.errorDescription ?? "Request failed"
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        if let store = store { await store.refreshAccounts(userId: userId) }
        else { await load() }
    }

    // MARK: - Mutations
    func create(name: String, type: String, currency: String, active: Bool) async -> Bool {
        do {
            let new = try await client.createAccount(
                userId: userId, name: name, type: type, currency: currency.uppercased(), active: active
            )
            if let store = store {
                await store.refreshAccounts(userId: userId)
                await store.refreshWatchlists(userId: userId)
            } else {
                var copy = items
                copy.append(new)
                self.items = sortAccounts(copy)
            }
            return true
        } catch let api as APIError {
            self.errorMessage = api.errorDescription ?? "Request failed"
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(_ account: Account) async -> Bool {
        do {
            try await client.deleteAccount(id: account.id)
            // Optimistic local update for responsiveness
            self.items.removeAll { $0.id == account.id }
            // Kick off background refreshes (don’t block UI)
            if let store = store {
                Task {
                    async let a: Void = store.refreshAccounts(userId: userId)
                    async let b: Void = store.refreshWatchlists(userId: userId)
                    _ = await (a, b)
                }
            }
            return true
        } catch let api as APIError {
            self.errorMessage = api.errorDescription ?? "Request failed"
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Aggregates
    var totalCurrent: Double { items.reduce(0) { $0 + $1.value.currentValue } }
    var totalInvested: Double { items.reduce(0) { $0 + $1.value.invested } }
    var totalPrevious: Double { items.reduce(0) { $0 + $1.value.previousValue } }
    var changeVsPrev: Double { totalCurrent - totalPrevious }
    var changePercent: Double? {
        let denom = abs(totalPrevious)
        guard denom > 0 else { return nil }
        return changeVsPrev / denom
    }

    var displayCurrency: String {
        (UserDefaults.standard.string(forKey: "defaultCurrencyCode") ?? "INR").uppercased()
    }

    // MARK: - Helpers
    private func sortAccounts(_ list: [Account]) -> [Account] {
        list.sorted { a, b in
            if a.type != b.type { return a.type.localizedCaseInsensitiveCompare(b.type) == .orderedAscending }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
