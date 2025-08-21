import Foundation
import SwiftUI

@MainActor
final class AccountsController: ObservableObject {
    @Published var items: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    let userId: Int
    private let client: RestClient

    init(userId: Int, service: RestClient = RestClient()) {
        self.userId = userId
        self.client = service
    }

    func load() async {
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

    func refresh() async { await load() }

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
