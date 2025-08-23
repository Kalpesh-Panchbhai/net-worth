import SwiftUI

struct AccountDetailView: View {
    let account: Account
    @AppStorage("defaultCurrencyCode") private var displayCurrency: String = "INR"
    @EnvironmentObject private var lookup: LookupStore
    @State private var brokerHoldings: [AccountBroker] = []
    @State private var isLoadingBroker = false
    @State private var brokerError: String? = nil
    @State private var transactions: [AccountTransaction] = []
    @State private var isLoadingTx = false
    @State private var txError: String? = nil
    @State private var showCreateTx = false
    // Watchlists containing this account
    @State private var accountWatchlists: [Watchlist] = []
    @State private var isLoadingWatches = false
    @State private var watchesError: String? = nil
    // Simplified transactions UI (no filters/search/summary)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary for this account
                let total = account.value.currentValue
                let invested = account.value.invested
                let previous = account.value.previousValue
                let changeVsPrev = total - previous
                let changePercent: Double? =
                    abs(previous) > 0 ? (changeVsPrev / abs(previous)) : nil

                AccountsSummaryCard(
                    total: total,
                    invested: invested,
                    changeVsPrev: changeVsPrev,
                    changePercent: changePercent,
                    currency: displayCurrency.uppercased()
                )

                // Account details
                SettingsGroup(title: "Account") {
                    VStack(spacing: 0) {
                        detailRow(icon: "person.crop.circle", title: "Name", subtitle: account.name)
                        divider()
                        detailRow(
                            icon: "square.grid.2x2", title: "Type",
                            subtitle: normalizedType(account.type))
                        divider()
                        detailRow(
                            icon: "coloncurrencysign.circle",
                            title: "Account currency",
                            subtitle: CurrencyCatalog.byCode[account.currency.uppercased()]?.name
                                ?? account.currency.uppercased(),
                            trailing: {
                                Text(account.currency.uppercased())
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        )
                        divider()
                        detailRow(
                            icon: account.active ? "checkmark.seal" : "xmark.seal",
                            title: "Status",
                            subtitle: account.active ? "Active" : "Inactive"
                        )
                    }
                }

                // Transactions (non-broker) — with watchlists shown above
                if normalizedType(account.type) != "Broker" {
                    // Show watchlists above transactions for non-broker accounts
                    watchlistsSection()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Showing last 5 transactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        if isLoadingTx && transactions.isEmpty {
                            ForEach(0..<5, id: \.self) { _ in transactionPlaceholderRow() }
                        } else if let err = txError {
                            VStack(spacing: 10) {
                                EmptyStateCard(
                                    text: err, icon: "exclamationmark.triangle", iconFont: .title3)
                                Button(action: { Task { await loadTransactions() } }) {
                                    Label("Retry", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else if transactions.isEmpty {
                            EmptyStateCard(
                                text: "No transactions yet", icon: "tray", iconFont: .title3)
                        } else {
                            let sortedAll = sortedTransactions(transactions)
                            let preview = Array(sortedAll.prefix(5))
                            VStack(spacing: 12) {
                                ForEach(preview.indices, id: \.self) { i in
                                    let tx = preview[i]
                                    let prevVal: Double? = (i + 1 < sortedAll.count) ? sortedAll[i + 1].value : nil
                                    transactionRowView(
                                        date: DateTZ.fromBackendISTStringToUserDate(tx.transactionDate) ?? Date(),
                                        value: tx.value,
                                        previousValue: prevVal,
                                        operation: tx.operation,
                                        currency: displayCurrency.uppercased()
                                    )
                                }
                            }
                        }
                    }
                }

                // Broker holdings
                if normalizedType(account.type) == "Broker" {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Holdings")
                            .font(.caption).bold()
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        if isLoadingBroker && brokerHoldings.isEmpty {
                            ForEach(0..<5, id: \.self) { _ in AssetRowCard.placeholder() }
                        } else if let err = brokerError {
                            VStack(spacing: 10) {
                                EmptyStateCard(
                                    text: err, icon: "exclamationmark.triangle", iconFont: .title3)
                                Button(action: { Task { await loadBroker() } }) {
                                    Label("Retry", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else if brokerHoldings.isEmpty {
                            EmptyStateCard(text: "No holdings yet", icon: "tray", iconFont: .title3)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(brokerHoldings, id: \.id) { h in
                                    NavigationLink(value: h) {
                                        AssetRowCard(
                                            name: h.name.isEmpty ? h.symbol : h.name,
                                            current: h.value.currentValue,
                                            invested: h.value.invested,
                                            previous: h.value.previousValue,
                                            currency: displayCurrency.uppercased(),
                                            units: h.currentUnit
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                // In watchlists (for broker accounts, keep below holdings)
                if normalizedType(account.type) == "Broker" {
                    watchlistsSection()
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, LayoutConstants.tabBarHeight + 24)
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .fabOverlay(icon: "plus", accessibilityLabel: "Add transaction", isVisible: normalizedType(account.type) != "Broker") {
            showCreateTx = true
            Haptics.selection()
        }
        .navigationDestination(for: AccountBroker.self) { holding in
            BrokerHoldingDetailView(holding: holding)
        }
        .navigationDestination(for: Watchlist.self) { item in
            WatchlistAccountsView(userId: account.userId, watchlist: item)
        }
        .sheet(isPresented: $showCreateTx) {
            NavigationStack {
                CreateTransactionView(
                    accountId: account.id,
                    accountBrokerId: 0,
                    onSaved: { Task { await loadTransactions() } }
                )
            }
        }
        .task {
            await loadBroker()
            await loadTransactions()
            await loadAccountWatches()
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private func detailRow<Trailing: View>(
        icon: String, title: String, subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        SettingsCell(icon: icon, title: title, subtitle: subtitle) {
            trailing()
        }
    }

    @ViewBuilder
    private func divider() -> some View {
        Rectangle().fill(Color.subtleSeparator)
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }

    private func normalizedType(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.contains("broker") { return "Broker" }
        if t.contains("saving") { return "Saving" }
        if t.contains("credit") { return "Credit card" }
        if t.contains("loan") { return "Loan" }
        return "Other"
    }

    @MainActor
    private func loadBroker() async {
        // Only for broker accounts, avoid duplicate loads
        guard normalizedType(account.type) == "Broker" else { return }
        if isLoadingBroker { return }
        isLoadingBroker = true
        brokerError = nil
        defer { isLoadingBroker = false }
        do {
            let items = try await RestClient().fetchAccountBroker(accountId: account.id)
            self.brokerHoldings = items.sorted { a, b in
                let an = a.name.isEmpty ? a.symbol : a.name
                let bn = b.name.isEmpty ? b.symbol : b.name
                return an.localizedCaseInsensitiveCompare(bn) == .orderedAscending
            }
        } catch let api as APIError {
            brokerError = api.errorDescription ?? "Failed to load holdings"
        } catch {
            brokerError = error.localizedDescription
        }
    }

    @MainActor
    private func loadTransactions() async {
        // Only for non-broker accounts
        guard normalizedType(account.type) != "Broker" else { return }
        if isLoadingTx { return }
        isLoadingTx = true
        txError = nil
        defer { isLoadingTx = false }
        do {
            let list = try await RestClient().fetchAccountTransactions(accountId: account.id)
            self.transactions = list
        } catch let api as APIError {
            txError = api.errorDescription ?? "Failed to load transactions"
        } catch {
            txError = error.localizedDescription
        }
    }

    @MainActor
    private func loadAccountWatches() async {
        if isLoadingWatches { return }
        isLoadingWatches = true
        watchesError = nil
        defer { isLoadingWatches = false }
        do {
            let links = try await RestClient().fetchWatchAccountsByAccount(accountId: account.id)
            let watchIds = Set(links.map { $0.watchId })
            // Ensure watchlists are available in store
            if lookup.watchlists.isEmpty { await lookup.loadWatchlistsIfNeeded(userId: account.userId) }
            let lists = lookup.watchlists.filter { watchIds.contains($0.id) }
            self.accountWatchlists = lists.sorted { a, b in
                let aIsAll = a.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("All") == .orderedSame
                let bIsAll = b.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare("All") == .orderedSame
                if aIsAll != bIsAll { return aIsAll && !bIsAll }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        } catch let api as APIError {
            watchesError = api.errorDescription ?? "Failed to load watchlists"
        } catch {
            watchesError = error.localizedDescription
        }
    }

    private func sortedTransactions(_ arr: [AccountTransaction]) -> [AccountTransaction] {
        arr.sorted { a, b in
            let da = DateTZ.fromBackendISTStringToUserDate(a.transactionDate) ?? .distantPast
            let db = DateTZ.fromBackendISTStringToUserDate(b.transactionDate) ?? .distantPast
            return da > db // newest first
        }
    }

    // MARK: - Watchlists section (reusable)
    @ViewBuilder
    private func watchlistsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In watchlists")
                .font(.caption).bold()
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            if isLoadingWatches && accountWatchlists.isEmpty {
                ForEach(0..<3, id: \.self) { _ in AssetRowCard.placeholder() }
            } else if let err = watchesError {
                EmptyStateCard(text: err, icon: "exclamationmark.triangle", iconFont: .title3)
            } else if accountWatchlists.isEmpty {
                EmptyStateCard(text: "Not in any watchlist", icon: "eye.slash", iconFont: .title3)
            } else {
                VStack(spacing: 12) {
                    ForEach(accountWatchlists, id: \.id) { wl in
                        NavigationLink(value: wl) {
                            AssetRowCard(
                                name: wl.name,
                                current: wl.value.currentValue,
                                invested: wl.value.invested,
                                previous: wl.value.previousValue,
                                currency: displayCurrency.uppercased(),
                                countBadge: wl.totalAccount > 0 ? wl.totalAccount : nil
                            )
                        }
                    }
                }
            }
        }
    }
}
