import SwiftUI

struct AccountsListView: View {
    @StateObject private var vm: AccountsController
    @State private var navCollapsed = false
    @AppStorage("hideInactiveAccounts") private var hideInactive: Bool = true
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var tabCommands: TabCommandCenter

    init(userId: Int) {
        _vm = StateObject(wrappedValue: AccountsController(userId: userId))
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

                        VStack(spacing: 16) {
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
                                    currency: vm.displayCurrency
                                )
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
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
                                let sections = groupedSections()
                                LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
                                    ForEach(sections, id: \.title) { section in
                                        Section {
                                            ForEach(section.items, id: \.id) { item in
                                                AccountRow(item: item)
                                            }
                                        } header: {
                                            let sectionTotal = section.items.reduce(0) { $0 + $1.value.currentValue }
                                            AccountSectionHeader(title: section.title, count: section.items.count, total: sectionTotal, currency: vm.displayCurrency)
                                                .padding(.top, 8)
                                        }
                                    }
                                }
                            }
                            Color.clear.frame(height: 1).id("accountsBottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .scrollIndicators(.hidden)
                    .coordinateSpace(name: "accountsScroll")
                }
                .onChange(of: tabCommands.scrollToBottomRequest) { _, req in
                    guard req == .accounts else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo("accountsBottom", anchor: .bottom)
                    }
                    DispatchQueue.main.async { tabCommands.scrollToBottomRequest = nil }
                }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
        }
        .task { await vm.load() }
        .refreshable { await vm.refresh() }
        .onChange(of: vm.errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            banners.showError(message: message, retryTitle: "Retry", retry: { Task { await vm.refresh() } })
        }
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
            Text("Net worth")
                .font(.subheadline)
                .foregroundColor(.secondary)
            // Primary value
            Text(total, format: .currency(code: currency))
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(LinearGradient.airbnbAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
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
                HStack {
                    Text("1 day change").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    let isUp = changeVsPrev >= 0
                    HStack(spacing: 6) {
                        Text(abs(changeVsPrev), format: .currency(code: currency))
                        if let p = changePercent {
                            Text("\(p, format: .percent.precision(.fractionLength(2)))")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isUp ? .airbnbSuccess : .red)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
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
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle().fill(Color.airbnbPrimary.opacity(0.10))
                Image(systemName: iconForType(item.type))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LinearGradient.airbnbAccent)
            }
            .frame(width: 36, height: 36)
            .overlay(Circle().stroke(Color.subtleSeparator, lineWidth: 1))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                    Text(CurrencyShort.shortString(item.value.currentValue, currency: item.currency))
                        .font(.headline.weight(.bold))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                HStack(spacing: 8) {
                    Text(normalizedAccountType(item.type))
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Capsule().fill(Color.airbnbPrimary.opacity(0.10)))
                        .overlay(
                            Capsule().stroke(Color.subtleSeparator, lineWidth: 0.8)
                        )
                    // Invested chip
                    HStack(spacing: 6) {
                        Text("Invested")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(CurrencyShort.shortString(item.value.invested, currency: item.currency))
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(Color.elevatedBackground))
                    .overlay(Capsule().stroke(Color.subtleSeparator, lineWidth: 0.8))
                    Spacer(minLength: 0)
                    let delta = item.value.currentValue - item.value.previousValue
                    if delta != 0 {
                        HStack(spacing: 4) {
                            Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2.weight(.bold))
                            let prev = item.value.previousValue
                            let pct = abs(prev) > 0 ? (delta / abs(prev)) : nil
                            Text(CurrencyShort.shortString(abs(delta), currency: item.currency))
                                .font(.caption2.weight(.semibold))
                            if let p = pct {
                                Text("• \(p, format: .percent.precision(.fractionLength(2)))")
                                    .font(.caption2.weight(.semibold))
                            }
                        }
                        .foregroundColor(delta >= 0 ? .airbnbSuccess : .red)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
        )
        .elevatedShadow()
        .buttonStyle(PressableButtonStyle())
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

    private func iconForType(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("broker") { return "building.columns" }
        if t.contains("saving") { return "banknote" }
        if t.contains("loan") { return "creditcard" }
        if t.contains("credit") { return "creditcard" }
        return "wallet.pass" // other
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
        let base = (anyInactive && hideInactive) ? vm.items.filter { $0.active } : vm.items
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
            Text(total, format: .currency(code: currency))
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
        .padding(.horizontal, 2)
        .padding(.vertical, 6)
        .background(Color.canvasBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.subtleSeparator).frame(height: 0.5)
        }
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
