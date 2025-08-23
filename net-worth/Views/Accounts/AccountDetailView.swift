import SwiftUI

struct AccountDetailView: View {
    let account: Account
    @AppStorage("defaultCurrencyCode") private var displayCurrency: String = "INR"
    @State private var brokerHoldings: [AccountBroker] = []
    @State private var isLoadingBroker = false
    @State private var brokerError: String? = nil
    @State private var transactions: [AccountTransaction] = []
    @State private var isLoadingTx = false
    @State private var txError: String? = nil
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

                // Transactions (non-broker) — simple preview + See all
                if normalizedType(account.type) != "Broker" {
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
                                    AssetRowCard(
                                        name: h.name.isEmpty ? h.symbol : h.name,
                                        current: h.value.currentValue,
                                        invested: h.value.invested,
                                        previous: h.value.previousValue,
                                        currency: displayCurrency.uppercased()
                                    )
                                }
                            }
                        }
                    }
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
        .task {
            await loadBroker()
            await loadTransactions()
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

    private func sortedTransactions(_ arr: [AccountTransaction]) -> [AccountTransaction] {
        arr.sorted { a, b in
            let da = DateTZ.fromBackendISTStringToUserDate(a.transactionDate) ?? .distantPast
            let db = DateTZ.fromBackendISTStringToUserDate(b.transactionDate) ?? .distantPast
            return da > db // newest first
        }
    }
}
