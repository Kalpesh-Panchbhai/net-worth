import SwiftUI

struct EntitySelection: Equatable {
    var type: ChartEntityType
    var id: Int
    var name: String
    var otherType: OtherChartType?
}

struct EntityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lookup: LookupStore

    let userId: Int
    var onPicked: (EntitySelection) -> Void

    @State private var selectedType: ChartEntityType = .account
    @State private var accounts: [AccountSummary] = []
    @State private var watchlists: [WatchlistSummary] = []
    @State private var holdings: [HoldingSummary] = []
    @State private var incomeSources: [IncomeSource] = []
    @State private var selectedAccountForHoldings: AccountSummary?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Type", selection: $selectedType) {
                    Text("Holding").tag(ChartEntityType.holding)
                    Text("Account").tag(ChartEntityType.account)
                    Text("Watchlist").tag(ChartEntityType.watchlist)
                    Text("Other").tag(ChartEntityType.other)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedType, initial: false) { _, _ in
                    selectedAccountForHoldings = nil
                    load()
                }

                content
            }
            .navigationTitle("Select Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { load() }
            .background(Color.canvasBackground.ignoresSafeArea())
            .toolbarBackground(Color.canvasBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView().tint(.airbnbPrimary).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if let msg = errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
                Text(msg).font(.footnote).multilineTextAlignment(.center)
                Button("Retry") { load() }.buttonStyle(.borderedProminent)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch selectedType {
            case .account:
                List(accounts, id: \.id) { acc in
                    Button { pick(.account, id: acc.id, name: acc.name) } label: {
                        row(title: acc.name, subtitle: displayTypeName(acc.type))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.canvasBackground)
            case .watchlist:
                List(watchlists, id: \.id) { wl in
                    Button { pick(.watchlist, id: wl.id, name: wl.name) } label: {
                        row(title: wl.name, subtitle: nil)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.canvasBackground)
            case .other:
                List(OtherChartType.allCases, id: \.self) { otherType in
                    Button { pick(.other, id: 0, name: otherType.displayName, otherType: otherType) } label: {
                        row(title: otherType.displayName, subtitle: nil)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.canvasBackground)
            case .holding:
                if let selectedAcc = selectedAccountForHoldings {
                    // Inline back chip to go back to accounts list
                    HStack {
                        Button(action: { selectedAccountForHoldings = nil; holdings = [] }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Accounts")
                            }
                            .font(.footnote.weight(.semibold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.secondary.opacity(0.14))
                            )
                        }
                        .buttonStyle(.plain)
                        Spacer(minLength: 8)
                        Text(selectedAcc.name)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    List(holdings, id: \.id) { h in
                        Button { pick(.holding, id: h.id, name: h.name) } label: {
                            row(title: h.name, subtitle: h.symbol)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.canvasBackground)
                    // back to accounts handled by toolbar at NavigationStack level
                } else {
                    List(accounts, id: \.id) { acc in
                        Button {
                            selectedAccountForHoldings = acc
                            Task { await loadHoldings(accountId: acc.id) }
                        } label: {
                            row(title: acc.name, subtitle: displayTypeName(acc.type))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.canvasBackground)
                }
            }
        }
    }

    private func row(title: String, subtitle: String?) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold))
                if let subtitle { Text(subtitle).font(.system(size: 12)).foregroundColor(.secondary) }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func pick(_ type: ChartEntityType, id: Int, name: String, otherType: OtherChartType? = nil) {
        onPicked(EntitySelection(type: type, id: id, name: name, otherType: otherType))
        dismiss()
    }

    // Map internal account type codes to user-friendly display names
    private func displayTypeName(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t == "broker" || t.contains("broker") { return "Broker" }
        if t == "savings" || t.contains("saving") { return "Savings" }
        if t == "credit_card" || t.contains("credit") { return "Credit Card" }
        if t == "loan" || t.contains("loan") { return "Loan" }
        return "Other"
    }

    private func load() {
        Task { await fetch() }
    }

    private func fetch() async {
        isLoading = true; errorMessage = nil
        switch selectedType {
        case .account:
            if !lookup.accounts.isEmpty {
                accounts = lookup.accounts
            } else {
                errorMessage = "No accounts available. Load data first."
            }
        case .watchlist:
            if !lookup.watchlists.isEmpty {
                watchlists = lookup.watchlists
            } else {
                errorMessage = "No watchlists available. Load data first."
            }
        case .other:
            // No loading needed for "Other" category - it's static options
            break
        case .holding:
            let brokers = lookup.accounts.filter { $0.type.lowercased() == "broker" }
            if !brokers.isEmpty {
                accounts = brokers
            } else {
                errorMessage = "No broker accounts available."
            }
        }
        isLoading = false
    }

    private func loadHoldings(accountId: Int) async {
        isLoading = true; errorMessage = nil
        // Try to load holdings if not already cached
        await lookup.loadHoldingsIfNeeded(accountId: accountId)
        if let cached = lookup.getHoldings(for: accountId), !cached.isEmpty {
            holdings = cached
        } else {
            errorMessage = "No holdings available for this account."
        }
        isLoading = false
    }
}

