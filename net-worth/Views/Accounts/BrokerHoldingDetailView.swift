import SwiftUI

struct BrokerHoldingDetailView: View {
    let holding: AccountBroker
    @AppStorage("defaultCurrencyCode") private var displayCurrency: String = "INR"

    @State private var transactions: [AccountTransaction] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary for this holding
                let total = holding.value.currentValue
                let invested = holding.value.invested
                let previous = holding.value.previousValue
                let changeVsPrev = total - previous
                let changePercent: Double? = abs(previous) > 0 ? (changeVsPrev / abs(previous)) : nil

                AccountsSummaryCard(
                    total: total,
                    invested: invested,
                    changeVsPrev: changeVsPrev,
                    changePercent: changePercent,
                    currency: displayCurrency.uppercased()
                )

                // Holding details
                SettingsGroup(title: "Holding") {
                    VStack(spacing: 0) {
                        SettingsCell(icon: "textformat", title: "Name", subtitle: (holding.name.isEmpty ? holding.symbol : holding.name)) { EmptyView() }
                        Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(.horizontal, 12)
                        SettingsCell(icon: "number", title: "Symbol", subtitle: holding.symbol) { EmptyView() }
                        Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(.horizontal, 12)
                        SettingsCell(icon: "chart.bar", title: "Units", subtitle: String(format: "%.2f", holding.currentUnit)) { EmptyView() }
                    }
                }

                // Transactions preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Showing last 5 transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    if isLoading && transactions.isEmpty {
                        ForEach(0..<5, id: \.self) { _ in transactionPlaceholderRow() }
                    } else if let err = errorMessage {
                        VStack(spacing: 10) {
                            EmptyStateCard(text: err, icon: "exclamationmark.triangle", iconFont: .title3)
                            Button(action: { Task { await refresh() } }) {
                                Label("Retry", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else if transactions.isEmpty {
                        EmptyStateCard(text: "No transactions yet", icon: "tray", iconFont: .title3)
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
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, LayoutConstants.tabBarHeight + 24)
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle((holding.name.isEmpty ? holding.symbol : holding.name))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await load() }
    }

    // MARK: - Data
    @MainActor
    private func load() async {
        if !transactions.isEmpty { return }
        await refresh()
    }

    @MainActor
    private func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let list = try await RestClient().fetchAccountBrokerTransactions(accountBrokerId: holding.id)
            self.transactions = list
        } catch let api as APIError {
            errorMessage = api.errorDescription ?? "Failed to load transactions"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sortedTransactions(_ arr: [AccountTransaction]) -> [AccountTransaction] {
        arr.sorted { a, b in
            let da = DateTZ.fromBackendISTStringToUserDate(a.transactionDate) ?? .distantPast
            let db = DateTZ.fromBackendISTStringToUserDate(b.transactionDate) ?? .distantPast
            return da > db
        }
    }
}
