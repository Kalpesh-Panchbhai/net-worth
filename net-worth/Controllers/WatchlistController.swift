import Foundation
import SwiftUI
import Combine

@MainActor
final class WatchlistController: ObservableObject {
    @Published var items: [WatchlistSummary] = []
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
        // Immediately sync with existing data
        self.items = sortWatchlists(store.watchlists)
        store.$watchlists
            .sink { [weak self] lists in
                guard let self = self else { return }
                self.items = self.sortWatchlists(lists)
            }
            .store(in: &cancellables)
    }

    func load() async {
        if let store = store {
            // Only load if we don't have data and aren't already loading
            if store.watchlists.isEmpty && !store.isLoadingWatchlists {
                isLoading = true
                errorMessage = nil
                await store.loadWatchlistsIfNeeded(userId: userId)
                isLoading = false
            }
            return
        }
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let list = try await client.fetchWatchlists(userId: userId)
            self.items = sortWatchlists(list)
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
        if let store = store { await store.refreshWatchlists(userId: userId) }
        else { await load() }
    }

    // MARK: - Aggregates
    var totalCurrent: Double { items.reduce(0) { $0 + $1.currentDayValue } }
    var totalPrevious: Double { items.reduce(0) { $0 + $1.previousDayValue } }
    var totalInvested: Double { items.reduce(0) { $0 + $1.invested } }

    var delta: Double { totalCurrent - totalInvested }
    var changeVsPrev: Double { totalCurrent - totalPrevious }
    var changePercent: Double? {
        let denom = abs(totalPrevious)
        guard denom > 0 else { return nil }
        return changeVsPrev / denom
    }

    var displayCurrency: String {
        (UserDefaults.standard.string(forKey: "defaultCurrencyCode") ?? "INR").uppercased()
    }

    // MARK: - Create
    func create(name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let created = try await client.createWatchlist(userId: userId, name: trimmed)
            // Convert Watchlist to WatchlistSummary with default values
            let summary = WatchlistSummary(
                id: created.id,
                userId: created.userId,
                name: created.name,
                currentDayValue: 0,
                previousDayValue: 0,
                invested: 0
            )
            var newItems = items
            newItems.append(summary)
            self.items = sortWatchlists(newItems)
            if let store = store { await store.refreshWatchlists(userId: userId) }
        } catch let api as APIError {
            self.errorMessage = api.errorDescription ?? "Request failed"
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete
    func delete(_ item: WatchlistSummary) async -> Bool {
        do {
            try await client.deleteWatchlist(id: item.id)
            self.items.removeAll { $0.id == item.id }
            if let store = store { await store.refreshWatchlists(userId: userId) }
            return true
        } catch let api as APIError {
            self.errorMessage = api.errorDescription ?? "Request failed"
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Rename
    func rename(_ item: WatchlistSummary, to newName: String) async -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        do {
            _ = try await client.updateWatchlist(id: item.id, name: trimmed)
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                var updated = items
                var changed = updated[idx]
                changed = WatchlistSummary(
                    id: changed.id,
                    userId: changed.userId,
                    name: trimmed,
                    currentDayValue: changed.currentDayValue,
                    previousDayValue: changed.previousDayValue,
                    invested: changed.invested
                )
                updated[idx] = changed
                self.items = sortWatchlists(updated)
            }
            if let store = store { await store.refreshWatchlists(userId: userId) }
            return true
        } catch let api as APIError {
            self.errorMessage = api.errorDescription ?? "Request failed"
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Helpers
    private func sortWatchlists(_ list: [WatchlistSummary]) -> [WatchlistSummary] {
        list.sorted { a, b in
            let aIsAll = a.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("All") == .orderedSame
            let bIsAll = b.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("All") == .orderedSame
            if aIsAll != bIsAll { return aIsAll && !bIsAll }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
