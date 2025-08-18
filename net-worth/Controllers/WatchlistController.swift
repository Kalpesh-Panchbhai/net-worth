import Foundation
import SwiftUI

@MainActor
final class WatchlistController: ObservableObject {
    @Published var items: [Watchlist] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    let userId: Int
    private let client: RestClient

    init(userId: Int, service: RestClient = RestClient()) {
        self.userId = userId
        self.client = service
    }

    func load() async {
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

    func refresh() async { await load() }

    // MARK: - Aggregates
    var totalCurrent: Double { items.reduce(0) { $0 + $1.value.currentValue } }
    var totalPrevious: Double { items.reduce(0) { $0 + $1.value.previousValue } }
    var totalInvested: Double { items.reduce(0) { $0 + $1.value.invested } }

    var delta: Double { totalCurrent - totalInvested }
    var changeVsPrev: Double { totalCurrent - totalPrevious }
    var changePercent: Double? {
        let denom = abs(totalPrevious)
        guard denom > 0 else { return nil }
        return changeVsPrev / denom
    }

    var displayCurrency: String { "INR" }

    // MARK: - Create
    func create(name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let created = try await client.createWatchlist(userId: userId, name: trimmed)
            var newItems = items
            newItems.append(created)
            self.items = sortWatchlists(newItems)
        } catch let api as APIError {
            self.errorMessage = api.errorDescription ?? "Request failed"
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers
    private func sortWatchlists(_ list: [Watchlist]) -> [Watchlist] {
        list.sorted { a, b in
            let aIsAll = a.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("All") == .orderedSame
            let bIsAll = b.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("All") == .orderedSame
            if aIsAll != bIsAll { return aIsAll && !bIsAll }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
