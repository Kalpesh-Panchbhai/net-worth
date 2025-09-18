import Foundation
import SwiftUI
import Combine

@MainActor
final class WatchAccountsController: ObservableObject {
    @Published var items: [AccountSummary] = []
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
            // Use new API endpoint to get accounts for watchlist
            let accountSummaries = try await client.fetchWatchlistAccounts(watchlistId: watchId)
            self.items = accountSummaries.sorted { a, b in
                if a.type != b.type {
                    return a.type.localizedCaseInsensitiveCompare(b.type) == .orderedAscending
                }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
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
            // Use new API endpoint to get accounts for watchlist
            let accountSummaries = try await client.fetchWatchlistAccounts(watchlistId: watchId)
            self.items = accountSummaries.sorted { a, b in
                if a.type != b.type {
                    return a.type.localizedCaseInsensitiveCompare(b.type) == .orderedAscending
                }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        } catch let api as APIError {
            self.errorMessage = api.errorDescription ?? "Request failed"
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteFromWatch(_ account: AccountSummary) async -> Bool {
        do {
            try await client.unlinkWatchlistAccount(watchlistId: watchId, accountId: account.id)
            // Update local state
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
    
    // Add method to link account to watchlist
    func addToWatch(_ account: AccountSummary) async -> Bool {
        do {
            try await client.linkWatchlistAccount(watchlistId: watchId, accountId: account.id)
            // Update local state
            if !items.contains(where: { $0.id == account.id }) {
                var newItems = items
                newItems.append(account)
                self.items = sortAccounts(newItems)
            }
            return true
        } catch let api as APIError {
            self.errorMessage = api.errorDescription ?? "Failed to add to watch."
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    private func sortAccounts(_ list: [AccountSummary]) -> [AccountSummary] {
        list.sorted { a, b in
            if a.type != b.type {
                return a.type.localizedCaseInsensitiveCompare(b.type) == .orderedAscending
            }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
