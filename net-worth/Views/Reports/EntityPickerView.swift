import SwiftUI

struct EntitySelection: Equatable {
    var type: ChartEntityType
    var id: Int
    var name: String
}

struct EntityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lookup: LookupStore

    let userId: Int
    var onPicked: (EntitySelection) -> Void

    @State private var selectedType: ChartEntityType = .watchlist
    @State private var accounts: [AccountSummary] = []
    @State private var watchlists: [WatchlistSummary] = []
    @State private var holdings: [HoldingSummary] = []
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
                if selectedType == .holding, selectedAccountForHoldings != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Accounts") { selectedAccountForHoldings = nil; holdings = [] }
                    }
                }
            }
            .onAppear { load() }
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
                        row(title: acc.name, subtitle: acc.type.capitalized)
                    }
                }
                .listStyle(.plain)
            case .watchlist:
                List(watchlists, id: \.id) { wl in
                    Button { pick(.watchlist, id: wl.id, name: wl.name) } label: {
                        row(title: wl.name, subtitle: nil)
                    }
                }
                .listStyle(.plain)
            case .holding:
                if selectedAccountForHoldings != nil {
                    List(holdings, id: \.id) { h in
                        Button { pick(.holding, id: h.id, name: h.name) } label: {
                            row(title: h.name, subtitle: h.symbol)
                        }
                    }
                    .listStyle(.plain)
                    // back to accounts handled by toolbar at NavigationStack level
                } else {
                    List(accounts, id: \.id) { acc in
                        Button {
                            selectedAccountForHoldings = acc
                            Task { await loadHoldings(accountId: acc.id) }
                        } label: {
                            row(title: acc.name, subtitle: acc.type.capitalized)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
    }

    private func row(title: String, subtitle: String?) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color.airbnbPrimary.opacity(0.15)).frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold))
                if let subtitle { Text(subtitle).font(.system(size: 12)).foregroundColor(.secondary) }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func pick(_ type: ChartEntityType, id: Int, name: String) {
        onPicked(EntitySelection(type: type, id: id, name: name))
        dismiss()
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
