import SwiftUI

struct WatchlistAccountsView: View {
    let userId: Int
    let watchlist: Watchlist
    @StateObject private var vm: WatchAccountsController
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"
    @AppStorage("hideInactiveAccounts") private var hideInactive: Bool = true
    @State private var searchText: String = ""
    @State private var selectedTypes: Set<String> = [] // empty = all
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var lookup: LookupStore

    init(userId: Int, watchlist: Watchlist) {
        self.userId = userId
        self.watchlist = watchlist
        _vm = StateObject(wrappedValue: WatchAccountsController(userId: userId, watchId: watchlist.id))
    }

    // Totals can be added later if needed

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                // Airbnb-style search just under the large title
                AppSearchBar(text: $searchText, placeholder: "Search accounts")
                    .padding(.horizontal, 0)

                if vm.isLoading && vm.items.isEmpty {
                    ForEach(0..<6, id: \.self) { _ in
                        AssetRowCard.placeholder()
                    }
                } else if filteredAccounts().isEmpty {
                    EmptyStateCard(text: "No accounts yet")
                } else {
                    let filtered = filteredAccounts()
                    let total = filtered.reduce(0) { $0 + $1.value.currentValue }
                    let invested = filtered.reduce(0) { $0 + $1.value.invested }
                    let previous = filtered.reduce(0) { $0 + $1.value.previousValue }
                    let changeVsPrev = total - previous
                    let changePercent: Double? = abs(previous) > 0 ? (changeVsPrev / abs(previous)) : nil
                    WatchAccountsSummaryCard(
                        total: total,
                        invested: invested,
                        changeVsPrev: changeVsPrev,
                        changePercent: changePercent,
                        currency: defaultCurrencyCode.uppercased()
                    )
                    .padding(.bottom, 12)

                    FiltersBar(types: availableTypes(), selectedTypes: $selectedTypes, hideInactive: $hideInactive)
                        .padding(.horizontal, 2)

                    let hasInactive = vm.items.contains { !$0.active }
                    if hasInactive {
                        HStack {
                            Toggle("Hide inactive", isOn: $hideInactive)
                                .toggleStyle(SwitchToggleStyle(tint: .airbnbPrimary))
                                .font(.subheadline.weight(.semibold))
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 2)
                    }

                    ForEach(groupedSections(), id: \.title) { section in
                        Section {
                            ForEach(section.items, id: \.id) { item in
                                AssetRowCard(
                                    name: item.name,
                                    current: item.value.currentValue,
                                    invested: item.value.invested,
                                    previous: item.value.previousValue,
                                    currency: defaultCurrencyCode.uppercased()
                                )
                            }
                        } header: {
                            let sectionTotal = section.items.reduce(0) { $0 + $1.value.currentValue }
                            AccountSectionHeaderLite(
                                title: section.title,
                                count: section.items.count,
                                total: sectionTotal,
                                currency: defaultCurrencyCode.uppercased()
                            )
                        }
                    }
                }
                Color.clear.frame(height: LayoutConstants.tabBarHeight + 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle(watchlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollIndicators(.hidden)
        .task {
            vm.attachStore(lookup)
            await vm.load()
        }
        .refreshable { await vm.refresh() }
        .onChange(of: vm.errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            banners.showError(message: message, retryTitle: "Retry", retry: { Task { await vm.refresh() } })
        }
    }
}

// MARK: - Helpers and UI components
private extension WatchlistAccountsView {
    func filteredAccounts() -> [Account] {
        let anyInactive = vm.items.contains { !$0.active }
        var base = (anyInactive && hideInactive) ? vm.items.filter { $0.active } : vm.items
        // Search filter
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            base = base.filter { $0.name.localizedCaseInsensitiveContains(q) }
        }
        // Type filters
        if !selectedTypes.isEmpty {
            base = base.filter { selectedTypes.contains(normalizedType($0.type)) }
        }
        return base
    }

    struct SectionData { let title: String; let items: [Account] }
    func groupedSections() -> [SectionData] {
        let base = filteredAccounts()
        let order = ["Broker", "Saving", "Credit card", "Loan", "Other"]
        var buckets: [String: [Account]] = [:]
        for acc in base { buckets[normalizedType(acc.type), default: []].append(acc) }
        var result: [SectionData] = []
        for key in order { if let arr = buckets[key], !arr.isEmpty { result.append(SectionData(title: key, items: arr)) } }
        let known = Set(order)
        let extras = buckets.keys.filter { !known.contains($0) }.sorted()
        for key in extras { if let arr = buckets[key], !arr.isEmpty { result.append(SectionData(title: key, items: arr)) } }
        return result
    }

    func normalizedType(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.contains("broker") { return "Broker" }
        if t.contains("saving") { return "Saving" }
        if t.contains("credit") { return "Credit card" }
        if t.contains("loan") { return "Loan" }
        return "Other"
    }

    func availableTypes() -> [String] {
        let base = filteredAccounts().map { normalizedType($0.type) }
        let unique = Array(Set(base)).sorted()
        let order = ["Broker", "Saving", "Credit card", "Loan", "Other"]
        return unique.sorted { a, b in
            let ia = order.firstIndex(of: a) ?? Int.max
            let ib = order.firstIndex(of: b) ?? Int.max
            if ia != ib { return ia < ib }
            return a < b
        }
    }
}

private struct FiltersBar: View {
    let types: [String]
    @Binding var selectedTypes: Set<String>
    @Binding var hideInactive: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !types.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isOn: selectedTypes.isEmpty) {
                            selectedTypes.removeAll()
                            Haptics.selection()
                        }
                        ForEach(types, id: \.self) { t in
                            FilterChip(title: t, isOn: selectedTypes.contains(t)) {
                                if selectedTypes.contains(t) { selectedTypes.remove(t) }
                                else { selectedTypes.insert(t) }
                                Haptics.selection()
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }
}

private struct AccountSectionHeaderLite: View {
    let title: String
    let count: Int
    let total: Double
    let currency: String
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Capsule().fill(Color.airbnbPrimary.opacity(0.12)).frame(width: 32, height: 22)
                Image(systemName: icon(for: title))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.airbnbPrimary)
            }
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Text(CurrencyShort.shortString(total, currency: currency))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .monospacedDigit()
            Text("\(count)")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Capsule(style: .continuous).fill(Color.elevatedBackground))
                .overlay(Capsule(style: .continuous).stroke(Color.subtleSeparator, lineWidth: 1))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
        .frame(maxWidth: .infinity)
        .zIndex(1)
    }
    private func icon(for title: String) -> String {
        let t = title.lowercased()
        if t.contains("broker") { return "building.columns" }
        if t.contains("saving") { return "banknote" }
        if t.contains("loan") { return "creditcard" }
        if t.contains("credit") { return "creditcard" }
        return "wallet.pass"
    }
}

private struct WatchAccountsSummaryCard: View {
    let total: Double
    let invested: Double
    let changeVsPrev: Double
    let changePercent: Double?
    let currency: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Total value")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(total, format: .currency(code: currency))
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(LinearGradient.airbnbAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .monospacedDigit()
                .contentTransition(.numericText())
            VStack(spacing: 8) {
                HStack {
                    Text("Invested").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text(invested, format: .currency(code: currency))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.airbnbPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                HStack(alignment: .center) {
                    Text("P/L").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    let pl = total - invested
                    let plPct: String? = invested.magnitude > 0 ? (pl / invested.magnitude).formatted(.percent.precision(.fractionLength(1))) : nil
                    WideStatPill(
                        icon: pl >= 0 ? "arrow.up.right" : "arrow.down.right",
                        value: abs(pl),
                        currency: currency,
                        percent: plPct,
                        tint: pl >= 0 ? .airbnbSuccess : .red
                    )
                }
                HStack(alignment: .center) {
                    Text("1 day change").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    let isUp = changeVsPrev >= 0
                    let pctText = changePercent.map { $0.formatted(.percent.precision(.fractionLength(1))) }
                    WideStatPill(
                        icon: isUp ? "arrow.up.right" : "arrow.down.right",
                        value: abs(changeVsPrev),
                        currency: currency,
                        percent: pctText,
                        tint: isUp ? .airbnbSuccess : .red
                    )
                }
            }
        }
        .padding(EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14))
        .frame(maxWidth: .infinity, minHeight: LayoutConstants.cardMinHeight)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
        .accessibilityElement(children: .combine)
    }
}
