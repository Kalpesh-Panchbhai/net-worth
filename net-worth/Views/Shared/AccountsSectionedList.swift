import SwiftUI

struct AccountsSectionedList: View {
    let items: [AccountSummary]
    let currency: String
    var isLoading: Bool = false
    var enableDelete: Bool = false
    var onDelete: ((AccountSummary) -> Void)? = nil
    var onAddToWatch: ((AccountSummary) -> Void)? = nil

    @AppStorage("hideInactiveAccounts") private var hideInactive: Bool = true
    @State private var searchText: String = ""
    @State private var selectedTypes: Set<String> = [] // empty = all

    init(
        items: [AccountSummary],
        currency: String,
        isLoading: Bool = false,
        enableDelete: Bool = false,
        onDelete: ((AccountSummary) -> Void)? = nil,
        onAddToWatch: ((AccountSummary) -> Void)? = nil
    ) {
        self.items = items
        self.currency = currency
        self.isLoading = isLoading
        self.enableDelete = enableDelete
        self.onDelete = onDelete
        self.onAddToWatch = onAddToWatch
    }

    // MARK: - Body
    var body: some View {
        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
            // Search
            AppSearchBar(text: $searchText, placeholder: "Search accounts")
                .padding(.horizontal, 0)

            if isLoading && items.isEmpty {
                ForEach(0..<6, id: \.self) { _ in AssetRowCard.placeholder() }
            } else if filteredAccounts().isEmpty {
                EmptyStateCard(text: "No accounts yet")
            } else {
                // Summary
                let filtered = filteredAccounts()
                let total = filtered.reduce(0) { $0 + $1.currentDayValue }
                let invested = filtered.reduce(0) { $0 + $1.invested }
                let previous = filtered.reduce(0) { $0 + $1.previousDayValue }
                let changeVsPrev = total - previous
                let changePercent: Double? = abs(previous) > 0 ? (changeVsPrev / abs(previous)) : nil
                
                AccountsSummaryCard(
                    total: total,
                    invested: invested,
                    changeVsPrev: changeVsPrev,
                    changePercent: changePercent,
                    currency: currency
                )
                .padding(.bottom, 12)

                // Filters + toggle
                AccountsFiltersBar(types: availableTypes(), selectedTypes: $selectedTypes)
                    .padding(.horizontal, 2)
                
                let hasInactive = items.contains { !$0.isActive }
                if hasInactive {
                    HStack {
                        Toggle("Hide inactive", isOn: $hideInactive)
                            .toggleStyle(SwitchToggleStyle(tint: .airbnbPrimary))
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 2)
                }

                // Sections
                ForEach(groupedSections(), id: \.title) { section in
                    Section {
                        ForEach(section.items, id: \.id) { item in
                            NavigationLink(value: item) {
                                AssetRowCard(
                                    name: item.name,
                                    current: item.currentDayValue,
                                    invested: item.invested,
                                    previous: item.previousDayValue,
                                    currency: currency
                                )
                            }
                            .contextMenu {
                                if let onAddToWatch {
                                    Button {
                                        onAddToWatch(item)
                                    } label: {
                                        Label("Add to watch", systemImage: "text.badge.plus")
                                    }
                                }
                                if enableDelete, let onDelete {
                                    Button(role: .destructive) {
                                        onDelete(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    } header: {
                        let sectionTotal = section.items.reduce(0) { $0 + $1.currentDayValue }
                        AccountsSectionHeader(title: section.title, count: section.items.count, total: sectionTotal, currency: currency)
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func filteredAccounts() -> [AccountSummary] {
        // Apply search + inactive, then chip selection
        var base = searchAndInactiveFiltered()
        if !selectedTypes.isEmpty { base = base.filter { selectedTypes.contains(normalizedType($0.type)) } }
        return base
    }

    // Chips should be computed from search + inactive only, so user can add more chips while searching
    private func searchAndInactiveFiltered() -> [AccountSummary] {
        items.filter { account in
            let matchesSearch = searchText.isEmpty || account.name.localizedCaseInsensitiveContains(searchText)
            let isActiveFilter = hideInactive ? account.isActive : true
            return matchesSearch && isActiveFilter
        }
    }

    private func normalizedType(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.contains("broker") { return "Broker" }
        if t.contains("saving") { return "Saving" }
        if t.contains("credit") { return "Credit card" }
        if t.contains("loan") { return "Loan" }
        return "Other"
    }

    private func availableTypes() -> [String] {
        // Derive from search+inactive results so chips remain available for multi-select
        let base = searchAndInactiveFiltered().map { normalizedType($0.type) }
        let unique = Array(Set(base)).sorted()
        let order = ["Broker", "Saving", "Credit card", "Loan", "Other"]
        return unique.sorted { a, b in
            let ia = order.firstIndex(of: a) ?? Int.max
            let ib = order.firstIndex(of: b) ?? Int.max
            if ia != ib { return ia < ib }
            return a < b
        }
    }

    private func groupedSections() -> [AccountSection] {
        return groupByType(filteredAccounts())
    }
    
    private func groupByType(_ accounts: [AccountSummary]) -> [AccountSection] {
        let order = ["Broker", "Saving", "Credit card", "Loan", "Other"]
        var buckets: [String: [AccountSummary]] = [:]
        for acc in accounts { buckets[normalizedType(acc.type), default: []].append(acc) }
        var result: [AccountSection] = []
        for key in order { if let arr = buckets[key], !arr.isEmpty { result.append(AccountSection(title: key, items: arr)) } }
        let known = Set(order)
        let extras = buckets.keys.filter { !known.contains($0) }.sorted()
        for key in extras { if let arr = buckets[key], !arr.isEmpty { result.append(AccountSection(title: key, items: arr)) } }
        return result
    }

    private struct AccountSection {
        let title: String
        let items: [AccountSummary]
    }
}

// MARK: - Shared subviews
struct AccountsSummaryCard: View {
    let total: Double
    let invested: Double
    let changeVsPrev: Double
    let changePercent: Double?
    let currency: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Total value").font(.subheadline).foregroundColor(.secondary)
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

struct AccountsSectionHeader: View {
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

struct AccountsFiltersBar: View {
    let types: [String]
    @Binding var selectedTypes: Set<String>
    init(types: [String], selectedTypes: Binding<Set<String>>) {
        self.types = types
        self._selectedTypes = selectedTypes
    }
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
