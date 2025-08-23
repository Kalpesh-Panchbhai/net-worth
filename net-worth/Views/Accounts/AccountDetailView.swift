import SwiftUI

struct AccountDetailView: View {
    let account: Account
    @AppStorage("defaultCurrencyCode") private var displayCurrency: String = "INR"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary for this account
                let total = account.value.currentValue
                let invested = account.value.invested
                let previous = account.value.previousValue
                let changeVsPrev = total - previous
                let changePercent: Double? = abs(previous) > 0 ? (changeVsPrev / abs(previous)) : nil

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
                        detailRow(icon: "square.grid.2x2", title: "Type", subtitle: normalizedType(account.type))
                        divider()
                        detailRow(
                            icon: "coloncurrencysign.circle",
                            title: "Account currency",
                            subtitle: CurrencyCatalog.byCode[account.currency.uppercased()]?.name ?? account.currency.uppercased(),
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
    }

    // MARK: - Subviews
    @ViewBuilder
    private func detailRow<Trailing: View>(icon: String, title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) -> some View {
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
}
