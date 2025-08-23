import Foundation
import SwiftUI
import Combine

@MainActor
final class WatchAccountsController: ObservableObject {
    @Published var items: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    let userId: Int
    let watchId: Int
    private let client: RestClient
    private var store: LookupStore? = nil
    private var links: [WatchAccount] = []
    private var cancellables = Set<AnyCancellable>()

    init(userId: Int, watchId: Int, service: RestClient = RestClient()) {
        self.userId = userId
        self.watchId = watchId
        self.client = service
    }

    func attachStore(_ store: LookupStore) {
        guard self.store == nil else { return }
        self.store = store
    }

    func load() async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await client.fetchWatchAccounts(watchId: watchId)
            self.links = fetched
            let ids = Set(fetched.map { $0.accountId })
            var accounts: [Account]
            if let store = store {
                if store.accounts.isEmpty {
                    await store.loadAccountsIfNeeded(userId: userId)
                }
                accounts = store.accounts
            } else {
                accounts = try await client.fetchAccounts(userId: userId)
            }
            self.items = sortAccounts(accounts.filter { ids.contains($0.id) })
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
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await client.fetchWatchAccounts(watchId: watchId)
            self.links = fetched
            let ids = Set(fetched.map { $0.accountId })
            var accounts: [Account]
            if let store = store {
                await store.refreshAccounts(userId: userId)
                accounts = store.accounts
            } else {
                accounts = try await client.fetchAccounts(userId: userId)
            }
            self.items = sortAccounts(accounts.filter { ids.contains($0.id) })
        } catch let api as APIError {
            self.errorMessage = api.errorDescription ?? "Request failed"
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteFromWatch(_ account: Account) async -> Bool {
        guard let link = links.first(where: { $0.accountId == account.id }) else {
            self.errorMessage = "Link not found for account."
            return false
        }
        do {
            try await client.deleteWatchAccount(id: link.id)
            // Update local state
            links.removeAll { $0.id == link.id }
            items.removeAll { $0.id == account.id }
            return true
        } catch let api as APIError {
            self.errorMessage = api.errorDescription ?? "Failed to remove from watch."
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    private func sortAccounts(_ list: [Account]) -> [Account] {
        list.sorted { a, b in
            if a.type != b.type {
                return a.type.localizedCaseInsensitiveCompare(b.type) == .orderedAscending
            }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
