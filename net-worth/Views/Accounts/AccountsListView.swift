import SwiftUI

struct AccountsListView: View {
    @StateObject private var vm: AccountsController
    @State private var navCollapsed = false
    @AppStorage("hideInactiveAccounts") private var hideInactive: Bool = true
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"
    @State private var searchText: String = ""
    @State private var selectedTypes: Set<String> = [] // empty = all
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var tabCommands: TabCommandCenter
    @EnvironmentObject private var lookup: LookupStore

    init(userId: Int) {
        _vm = StateObject(wrappedValue: AccountsController(userId: userId))
    }

    // Split out heavy content to help the compiler
    @ViewBuilder
    private var contentView: some View {
        if vm.isLoading && vm.items.isEmpty {
            ForEach(0..<6, id: \.self) { _ in
                AccountRow.placeholder()
            }
            .shimmer()
        } else if vm.items.isEmpty {
            EmptyStateCard(text: "No accounts yet")
        } else {
            AccountSummaryCard(
                total: vm.totalCurrent,
                invested: vm.totalInvested,
                changeVsPrev: vm.changeVsPrev,
                changePercent: vm.changePercent,
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
                        AccountRow(item: item, currency: defaultCurrencyCode.uppercased())
                    }
                } header: {
                    let sectionTotal = section.items.reduce(0) { $0 + $1.value.currentValue }
                    AccountSectionHeader(title: section.title, count: section.items.count, total: sectionTotal, currency: defaultCurrencyCode.uppercased())
                }
            }
        }
    }

// MARK: - Airbnb-style SearchBar
private struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }
}

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .top) {
                    Color.canvasBackground.ignoresSafeArea()
                    ScrollView {
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: NavBarOffsetKey.self,
                                value: geo.frame(in: .named("accountsScroll")).minY
                            )
                        }
                        .frame(height: 0)

                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            // Airbnb-style search just under the large title
                            SearchBar(text: $searchText, placeholder: "Search accounts")
                                .padding(.horizontal, 0)
                            contentView
                            Color.clear.frame(height: LayoutConstants.tabBarHeight + 24).id("accountsBottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, LayoutConstants.tabBarHeight + 24)
                    }
                    .background(ScrollToTopEnabler())
                    .scrollIndicators(.hidden)
                    .coordinateSpace(name: "accountsScroll")
                }
                .onChange(of: tabCommands.scrollToBottomRequest) { _, value in
                    guard value != nil else { return }
                    withAnimation { proxy.scrollTo("accountsBottom", anchor: .bottom) }
                    DispatchQueue.main.async { tabCommands.scrollToBottomRequest = nil }
                }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
            // Custom search bar used instead of .searchable for brand styling
        }
        .onAppear { vm.attachStore(lookup) }
        .task { await vm.load() }
        .refreshable { await vm.refresh() }
        .onChange(of: vm.errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            banners.showError(message: message, retryTitle: "Retry", retry: { Task { await vm.refresh() } })
        }
    }
}

// Wide filled pill used on the right of labels like "P/L" and "1 day change"
private struct WideStatPill: View {
    let icon: String
    let value: Double
    let currency: String
    let percent: String?
    let tint: Color
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2.weight(.bold))
            Text(CurrencyShort.shortString(value, currency: currency))
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            if let p = percent, p.isEmpty == false {
                Text("•").font(.caption2.weight(.semibold))
                Text(p)
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
        }
        .foregroundColor(tint)
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(
            Capsule().fill(tint.opacity(0.12))
        )
    }
}

private struct AccountSummaryCard: View {
    let total: Double
    let invested: Double
    let changeVsPrev: Double
    let changePercent: Double?
    let currency: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title
            Text("Total value")
                .font(.subheadline)
                .foregroundColor(.secondary)
            // Primary value
            Text(total, format: .currency(code: currency))
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(LinearGradient.airbnbAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .monospacedDigit()
                .contentTransition(.numericText())
            // Rows
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
                // P&L row
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

// StatChip removed in compact design

private struct EmptyStateCard: View {
    let text: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray").font(.title2).foregroundColor(.secondary)
            Text(text).font(.subheadline.weight(.semibold)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
        )
        .elevatedShadow()
    }
}


private struct AccountRow: View {
    let item: Account
    let currency: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Removed leading icon to simplify rows and align with request
            VStack(alignment: .leading, spacing: 6) {
                header
                meta
                stats
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: LayoutConstants.cardMinHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Subviews to simplify type-checking
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(item.name)
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
            Text(item.value.currentValue, format: .currency(code: currency))
                .font(.headline.weight(.bold))
                .foregroundColor(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }

    private var meta: some View {
        HStack(spacing: 8) {
            Text("Invested")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer(minLength: 0)
            Text(item.value.invested, format: .currency(code: currency))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.airbnbPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }

    private var stats: some View {
        let invested = item.value.invested
        let totalPL = item.value.currentValue - invested
        let plPct: Double? = invested.magnitude > 0 ? (totalPL / invested.magnitude) : nil
        let plPctText: String? = plPct.map { $0.formatted(.percent.precision(.fractionLength(1))) }

        let dayDelta = item.value.currentValue - item.value.previousValue
        let dayPrev = item.value.previousValue
        let dayPct: Double? = dayPrev.magnitude > 0 ? (dayDelta / dayPrev.magnitude) : nil
        let dayPctText: String? = dayPct.map { $0.formatted(.percent.precision(.fractionLength(1))) }

        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text("P/L")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
                WideStatPill(
                    icon: totalPL >= 0 ? "arrow.up.right" : "arrow.down.right",
                    value: abs(totalPL),
                    currency: currency,
                    percent: plPctText,
                    tint: totalPL >= 0 ? .airbnbSuccess : .red
                )
            }
            HStack(spacing: 10) {
                Text("1 day change")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
                WideStatPill(
                    icon: dayDelta >= 0 ? "arrow.up.right" : "arrow.down.right",
                    value: abs(dayDelta),
                    currency: currency,
                    percent: dayPctText,
                    tint: dayDelta >= 0 ? .airbnbSuccess : .red
                )
            }
        }
    }

    static func placeholder() -> some View {
        HStack(alignment: .center, spacing: 12) {
            Circle().fill(Color.airbnbPrimary.opacity(0.12)).frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(width: 140, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(width: 100, height: 10)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 6).fill(Color.placeholderFill).frame(width: 80, height: 14)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
        )
    }

    // Icon removed as per design; keep helper if needed in future
    private func iconForType(_ type: String) -> String { "" }
}

// Compact tinted pill for stats like P&L and 1D
private struct StatPill: View {
    let label: String
    let icon: String?
    let value: String
    let percent: String?
    let tint: Color
    var body: some View {
        // Heuristic: hide percent if combined text would likely overflow the fixed pill width
        let showPercent: Bool = {
            guard let p = percent else { return false }
            // value like "₹21.3 K" ~ up to 8 chars, percent like "12.3%" ~ up to 6
            // allow percent only when both are reasonably short
            return value.count <= 9 && p.count <= 6
        }()
        HStack(spacing: 3) {
            if let icon { Image(systemName: icon).font(.caption2.weight(.bold)) }
            Text(value)
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
                .allowsTightening(true)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
            if showPercent, let p = percent {
                Text("•").font(.caption2.weight(.semibold))
                Text(p)
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .allowsTightening(true)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .contentTransition(.numericText())
            }
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8)
        .frame(width: LayoutConstants.statPillWidth, height: 24, alignment: .trailing)
        .background(
            Capsule().fill(tint.opacity(0.10))
        )
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

private struct TypeBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(Capsule().fill(Color.elevatedBackground))
    }
}

// File-scope helper so rows can normalize labels consistently with grouping
private func normalizedAccountType(_ raw: String) -> String {
    let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if t.contains("broker") { return "Broker" }
    if t.contains("saving") { return "Saving" }
    if t.contains("loan") { return "Loan" }
    if t.contains("credit") { return "Loan" }
    return "Other"
}

// MARK: - Grouping Helpers
private extension AccountsListView {
    struct SectionData { let title: String; let items: [Account] }
    func groupedSections() -> [SectionData] {
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
        let order = ["Broker", "Saving", "Loan", "Other"]
        var buckets: [String: [Account]] = [:]
        for acc in base {
            let t = normalizedType(acc.type)
            buckets[t, default: []].append(acc)
        }
        var result: [SectionData] = []
        for key in order {
            if let arr = buckets[key], !arr.isEmpty { result.append(SectionData(title: key, items: arr)) }
        }
        let known = Set(order)
        let extras = buckets.keys.filter { !known.contains($0) }.sorted()
        for key in extras {
            if let arr = buckets[key], !arr.isEmpty { result.append(SectionData(title: key, items: arr)) }
        }
        return result
    }
    func normalizedType(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.contains("broker") { return "Broker" }
        if t.contains("saving") { return "Saving" }
        if t.contains("loan") { return "Loan" }
        if t.contains("credit") { return "Loan" }
        return "Other"
    }
    func availableTypes() -> [String] {
        let base = vm.items.map { normalizedType($0.type) }
        let unique = Array(Set(base)).sorted()
        let order = ["Broker", "Saving", "Loan", "Other"]
        return unique.sorted { a, b in
            let ia = order.firstIndex(of: a) ?? Int.max
            let ib = order.firstIndex(of: b) ?? Int.max
            if ia != ib { return ia < ib }
            return a < b
        }
    }
}

// MARK: - Filters Bar
private struct FiltersBar: View {
    let types: [String]
    @Binding var selectedTypes: Set<String>
    @Binding var hideInactive: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Types chips
            if !types.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Chip(title: "All", isOn: selectedTypes.isEmpty) {
                            selectedTypes.removeAll()
                            Haptics.selection()
                        }
                        ForEach(types, id: \.self) { t in
                            Chip(title: t, isOn: selectedTypes.contains(t)) {
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

private struct Chip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isOn ? .white : .airbnbPrimary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                ZStack {
                    Capsule().fill(Color.airbnbPrimary.opacity(0.12))
                    if isOn { Capsule().fill(LinearGradient.airbnbAccent) }
                }
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Section Header
private struct AccountSectionHeader: View {
    let title: String
    let count: Int
    let total: Double
    let currency: String
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Capsule()
                    .fill(Color.airbnbPrimary.opacity(0.12))
                    .frame(width: 32, height: 22)
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
            // Total for this section
            Text(CurrencyShort.shortString(total, currency: currency))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .monospacedDigit()
            // Count pill
            Text("\(count)")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.elevatedBackground)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.subtleSeparator, lineWidth: 1)
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
        .frame(maxWidth: .infinity)
        .zIndex(1) // keep header above rows while pinned
    }
    private func icon(for title: String) -> String {
        let t = title.lowercased()
        if t.contains("broker") { return "building.columns" }
        if t.contains("saving") { return "banknote" }
        if t.contains("loan") { return "creditcard" }
        if t.contains("credit") { return "creditcard" }
        return "wallet.pass" // other
    }
}
