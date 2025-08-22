import Foundation
import SwiftUI

@MainActor
final class LookupStore: ObservableObject {
    @Published private(set) var incomeTypes: [IncomeType] = []
    @Published private(set) var incomeTags: [IncomeTag] = []
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var watchlists: [Watchlist] = []
    @Published private(set) var incomes: [Income] = []

    private var typesLoaded = false
    private var tagsLoaded = false
    private var accountsLoaded = false
    private var watchlistsLoaded = false
    private var incomesLoaded = false
    // In-flight guards for initial loads (prevent duplicate concurrent GETs)
    private var typesLoading = false
    private var tagsLoading = false
    private var accountsLoading = false
    private var watchlistsLoading = false
    private var incomesLoading = false
    private var typesRefreshing = false
    private var tagsRefreshing = false
    private var accountsRefreshing = false
    private var watchlistsRefreshing = false
    private var incomesRefreshing = false
    private let client = RestClient()

    func loadIfNeeded(userId: Int) async {
        async let a: Void = loadIncomeTypesIfNeeded(userId: userId)
        async let b: Void = loadIncomeTagsIfNeeded(userId: userId)
        async let c: Void = loadAccountsIfNeeded(userId: userId)
        async let d: Void = loadWatchlistsIfNeeded(userId: userId)
        async let e: Void = loadIncomesIfNeeded(userId: userId)
        _ = await (a, b, c, d, e)
    }

    func loadIncomeTypesIfNeeded(userId: Int) async {
        if typesLoaded || typesLoading { return }
        typesLoading = true
        defer { typesLoading = false }
        do {
            let list = try await client.fetchIncomeTypes(userId: userId)
            self.incomeTypes = list
            self.typesLoaded = true
        } catch {
            // keep empty; caller can retry
        }
    }

    func loadIncomeTagsIfNeeded(userId: Int) async {
        if tagsLoaded || tagsLoading { return }
        tagsLoading = true
        defer { tagsLoading = false }
        do {
            let list = try await client.fetchIncomeTags(userId: userId)
            self.incomeTags = list
            self.tagsLoaded = true
        } catch {
            // keep empty; caller can retry
        }
    }

    func loadAccountsIfNeeded(userId: Int) async {
        if accountsLoaded || accountsLoading { return }
        accountsLoading = true
        defer { accountsLoading = false }
        do {
            let list: [Account] = try await client.fetchAccounts(userId: userId)
            self.accounts = list.sorted { a, b in
                if a.type != b.type { return a.type.localizedCaseInsensitiveCompare(b.type) == .orderedAscending }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            self.accountsLoaded = true
        } catch {
            // keep empty; caller can retry
        }
    }

    func loadWatchlistsIfNeeded(userId: Int) async {
        if watchlistsLoaded || watchlistsLoading { return }
        watchlistsLoading = true
        defer { watchlistsLoading = false }
        do {
            let list: [Watchlist] = try await client.fetchWatchlists(userId: userId)
            self.watchlists = list.sorted { a, b in
                let aIsAll = a.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("All") == .orderedSame
                let bIsAll = b.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("All") == .orderedSame
                if aIsAll != bIsAll { return aIsAll && !bIsAll }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            self.watchlistsLoaded = true
        } catch {
            // keep empty; caller can retry
        }
    }

    func loadIncomesIfNeeded(userId: Int) async {
        if incomesLoaded || incomesLoading { return }
        incomesLoading = true
        defer { incomesLoading = false }
        do {
            let list: [Income] = try await client.fetchIncomes(userId: userId)
            self.incomes = list.sorted { $0.creditedDate > $1.creditedDate }
            self.incomesLoaded = true
        } catch {
            // keep empty; caller can retry
        }
    }

    // Explicit refreshers (allowed after mutations)
    func refreshIncomeTypes(userId: Int) async {
        if typesRefreshing { return }
        typesRefreshing = true
        defer { typesRefreshing = false }
        do {
            let list = try await client.fetchIncomeTypes(userId: userId)
            self.incomeTypes = list
            self.typesLoaded = true
        } catch {
            // no-op
        }
    }

    func refreshIncomeTags(userId: Int) async {
        if tagsRefreshing { return }
        tagsRefreshing = true
        defer { tagsRefreshing = false }
        do {
            let list = try await client.fetchIncomeTags(userId: userId)
            self.incomeTags = list
            self.tagsLoaded = true
        } catch {
            // no-op
        }
    }

    func refreshAccounts(userId: Int) async {
        if accountsRefreshing { return }
        accountsRefreshing = true
        defer { accountsRefreshing = false }
        do {
            let list: [Account] = try await client.fetchAccounts(userId: userId)
            self.accounts = list.sorted { a, b in
                if a.type != b.type { return a.type.localizedCaseInsensitiveCompare(b.type) == .orderedAscending }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            self.accountsLoaded = true
        } catch {
            // no-op
        }
    }

    func refreshWatchlists(userId: Int) async {
        if watchlistsRefreshing { return }
        watchlistsRefreshing = true
        defer { watchlistsRefreshing = false }
        do {
            let list: [Watchlist] = try await client.fetchWatchlists(userId: userId)
            self.watchlists = list.sorted { a, b in
                let aIsAll = a.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("All") == .orderedSame
                let bIsAll = b.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("All") == .orderedSame
                if aIsAll != bIsAll { return aIsAll && !bIsAll }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            self.watchlistsLoaded = true
        } catch {
            // no-op
        }
    }

    func refreshIncomes(userId: Int) async {
        if incomesRefreshing { return }
        incomesRefreshing = true
        defer { incomesRefreshing = false }
        do {
            let list: [Income] = try await client.fetchIncomes(userId: userId)
            self.incomes = list.sorted { $0.creditedDate > $1.creditedDate }
            self.incomesLoaded = true
        } catch {
            // no-op
        }
    }

    // Wipe all in-memory data and flags (used on logout)
    func reset() {
        // Clear data
        incomeTypes = []
        incomeTags = []
        accounts = []
        watchlists = []
        incomes = []
        // Reset loaded flags
        typesLoaded = false
        tagsLoaded = false
        accountsLoaded = false
        watchlistsLoaded = false
        incomesLoaded = false
        // Cancel loading/refreshing guards
        typesLoading = false
        tagsLoading = false
        accountsLoading = false
        watchlistsLoading = false
        incomesLoading = false
        typesRefreshing = false
        tagsRefreshing = false
        accountsRefreshing = false
        watchlistsRefreshing = false
        incomesRefreshing = false
    }
}
