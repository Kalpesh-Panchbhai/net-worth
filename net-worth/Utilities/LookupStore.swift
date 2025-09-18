import Foundation
import SwiftUI

@MainActor
final class LookupStore: ObservableObject {
    @Published private(set) var incomeSources: [IncomeSource] = []
    @Published private(set) var incomeTags: [IncomeTag] = []
    @Published private(set) var accounts: [AccountSummary] = []
    @Published private(set) var watchlists: [WatchlistSummary] = []
    @Published private(set) var incomes: [Income] = []
    
    // Loading states for UI
    @Published private(set) var isLoadingAccounts = false
    @Published private(set) var isLoadingWatchlists = false
    @Published private(set) var isLoadingIncomes = false
    // Keyed by accountId; populated elsewhere after a holdings fetch
    @Published private(set) var holdingsByAccount: [Int: [HoldingSummary]] = [:]

    private var sourcesLoaded = false
    private var tagsLoaded = false
    private var accountsLoaded = false
    private var watchlistsLoaded = false
    private var incomesLoaded = false
    // In-flight guards for initial loads (prevent duplicate concurrent GETs)
    private var sourcesLoading = false
    private var tagsLoading = false
    private var accountsLoading = false {
        didSet { isLoadingAccounts = accountsLoading }
    }
    private var watchlistsLoading = false {
        didSet { isLoadingWatchlists = watchlistsLoading }
    }
    private var incomesLoading = false {
        didSet { isLoadingIncomes = incomesLoading }
    }
    private var sourcesRefreshing = false
    private var tagsRefreshing = false
    private var accountsRefreshing = false
    private var watchlistsRefreshing = false
    private var incomesRefreshing = false
    // Holdings guards per accountId
    private var holdingsLoadedIds: Set<Int> = []
    private var holdingsLoadingIds: Set<Int> = []
    private var holdingsRefreshingIds: Set<Int> = []
    private let client = RestClient()

    func loadIfNeeded(userId: Int) async {
        async let a: Void = loadIncomeSourcesIfNeeded(userId: userId)
        async let b: Void = loadIncomeTagsIfNeeded(userId: userId)
        async let c: Void = loadAccountsIfNeeded(userId: userId)
        async let d: Void = loadWatchlistsIfNeeded(userId: userId)
        async let e: Void = loadIncomesIfNeeded(userId: userId)
        _ = await (a, b, c, d, e)
    }

    // MARK: - Holdings cache helpers (no network here)
    func setHoldings(_ holdings: [HoldingSummary], for accountId: Int) {
        holdingsByAccount[accountId] = holdings
        objectWillChange.send()
    }
    func getHoldings(for accountId: Int) -> [HoldingSummary]? {
        holdingsByAccount[accountId]
    }

    // MARK: - Holdings loaders (network)
    func loadHoldingsIfNeeded(accountId: Int) async {
        if holdingsLoadedIds.contains(accountId) || holdingsLoadingIds.contains(accountId) { return }
        holdingsLoadingIds.insert(accountId)
        defer { holdingsLoadingIds.remove(accountId) }
        do {
            let list = try await client.fetchHoldings(accountId: accountId)
            holdingsByAccount[accountId] = list
            holdingsLoadedIds.insert(accountId)
            objectWillChange.send()
        } catch {
            // keep old cache; allow retry later
        }
    }

    func refreshHoldings(accountId: Int) async {
        if holdingsRefreshingIds.contains(accountId) { return }
        holdingsRefreshingIds.insert(accountId)
        defer { holdingsRefreshingIds.remove(accountId) }
        do {
            let list = try await client.fetchHoldings(accountId: accountId)
            holdingsByAccount[accountId] = list
            holdingsLoadedIds.insert(accountId)
            objectWillChange.send()
        } catch {
            // no-op
        }
    }

    func loadIncomeSourcesIfNeeded(userId: Int) async {
        if sourcesLoaded || sourcesLoading { return }
        sourcesLoading = true
        defer { sourcesLoading = false }
        do {
            let list = try await client.fetchIncomeSources(userId: userId)
            self.incomeSources = list
            self.sourcesLoaded = true
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
            let list: [AccountSummary] = try await client.fetchAccounts(userId: userId)
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
            let list: [WatchlistSummary] = try await client.fetchWatchlists(userId: userId)
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
    func refreshIncomeSources(userId: Int) async {
        if sourcesRefreshing { return }
        sourcesRefreshing = true
        defer { sourcesRefreshing = false }
        do {
            let list = try await client.fetchIncomeSources(userId: userId)
            self.incomeSources = list
            self.sourcesLoaded = true
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
            let list: [AccountSummary] = try await client.fetchAccounts(userId: userId)
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
            let list: [WatchlistSummary] = try await client.fetchWatchlists(userId: userId)
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
        incomeSources = []
        incomeTags = []
        accounts = []
        watchlists = []
        incomes = []
        // Reset loaded flags
        sourcesLoaded = false
        tagsLoaded = false
        accountsLoaded = false
        watchlistsLoaded = false
        incomesLoaded = false
        // Cancel loading/refreshing guards
        sourcesLoading = false
        tagsLoading = false
        accountsLoading = false
        watchlistsLoading = false
        incomesLoading = false
        sourcesRefreshing = false
        tagsRefreshing = false
        accountsRefreshing = false
        watchlistsRefreshing = false
        incomesRefreshing = false
    }
}
