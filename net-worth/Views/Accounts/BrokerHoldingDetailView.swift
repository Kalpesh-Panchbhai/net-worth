import SwiftUI

struct BrokerHoldingDetailView: View {
    let holding: AccountBroker
    let isAccountActive: Bool
    @AppStorage("defaultCurrencyCode") private var displayCurrency: String = "INR"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var transactions: [AccountTransaction] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showCreateTx = false
    @State private var showReportsModal = false
    // Micro-interactions for toolbar button
    @State private var breathe = false
    @State private var rippleTrigger = false

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
                                let prevInvested: Double? = (i + 1 < sortedAll.count) ? sortedAll[i + 1].invested : nil
                                transactionRowView(
                                    date: DateTZ.fromBackendISTStringToUserDate(tx.transactionDate) ?? Date(),
                                    value: tx.value,
                                    previousValue: prevVal,
                                    operation: tx.operation,
                                    currency: displayCurrency.uppercased(),
                                    invested: tx.invested,
                                    previousInvested: prevInvested,
                                    showUnits: true
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { trendToolbarButton }
        }
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .fabOverlay(icon: "plus", accessibilityLabel: "Add transaction", isVisible: isAccountActive) {
            showCreateTx = true
            Haptics.selection()
        }
        .sheet(isPresented: $showCreateTx) {
            NavigationStack {
                CreateTransactionView(
                    accountId: holding.accountId,
                    holdingId: holding.id,
                    needsDailyData: false,
                    onSaved: { Task { await refresh() } }
                )
            }
        }
        .fullScreenCover(isPresented: $showReportsModal) {
            NavigationStack {
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        Color.canvasBackground.ignoresSafeArea()
                        AssetOverviewCard(
                            preselect: (
                                type: .holding,
                                id: holding.id,
                                name: (holding.name.isEmpty ? holding.symbol : holding.name)
                            )
                        )
                            .padding(.horizontal)
                            .padding(.top)
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    }
                }
                .navigationTitle("Reports")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") { showReportsModal = false }
                    }
                }
                .toolbarBackground(Color.canvasBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
        .task { await refresh() }
    }

    // MARK: - Toolbar Button
    private var trendToolbarButton: some View {
        Button {
            Haptics.selection()
            showReportsModal = true
            // Tap ripple feedback (respect Reduce Motion)
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) { rippleTrigger.toggle() }
            // Reset ripple after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { withAnimation(.easeOut(duration: 0.25)) { rippleTrigger = false } }
        } label: {
            ZStack {
                // Soft radial glow behind the button
                Circle()
                    .fill(Color.airbnbPrimary.opacity(0.22))
                    .blur(radius: 10)
                    .scaleEffect(breathe ? 1.08 : 0.96)
                    .opacity(0.8)

                Circle()
                    .fill(LinearGradient.airbnbAccent)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                    )
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .padding(1)
                            .opacity(0.7)
                    )

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 1)

                // Ripple ring
                Circle()
                    .stroke(LinearGradient.airbnbAccent, lineWidth: 2)
                    .scaleEffect(rippleTrigger ? 1.7 : 0.9)
                    .opacity(rippleTrigger ? 0.35 : 0.0)
                    .animation(.easeOut(duration: 0.6), value: rippleTrigger)
            }
            .frame(width: 34, height: 34)
            .shadow(color: Color.airbnbPrimary.opacity(0.25), radius: 8, x: 0, y: 4)
            .scaleEffect(reduceMotion ? 1.0 : (breathe ? 1.02 : 0.98))
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathe)
            .onAppear { if !reduceMotion { breathe = true } }
        }
        .buttonStyle(PressableButtonStyle(scale: 0.96))
        .accessibilityLabel("View Trends")
    }

    // MARK: - Data
    @MainActor
    private func load() async { await refresh() }

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
