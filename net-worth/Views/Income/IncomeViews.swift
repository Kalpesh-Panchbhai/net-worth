import SwiftUI

// MARK: - Currency helpers
private func sfSymbolForCurrency(code: String) -> String? {
    switch code.uppercased() {
    case "USD", "CAD", "AUD", "NZD", "SGD", "HKD", "MXN", "ARS", "CLP": return "dollarsign.circle"
    case "EUR": return "eurosign.circle"
    case "GBP": return "sterlingsign.circle"
    case "JPY", "CNY": return "yensign.circle"
    case "INR": return "indianrupeesign.circle"
    case "KRW": return "wonsign.circle"
    case "RUB": return "rublesign.circle"
    case "TRY": return "turkishlirasign.circle"
    case "THB": return "bahtsign.circle"
    case "ILS": return "shekelsign.circle"
    default: return nil
    }
}
private struct CurrencyBadge: View {
    let code: String
    var body: some View {
        ZStack {
            Circle().fill(Color.airbnbPrimary.opacity(0.12))
            if let icon = sfSymbolForCurrency(code: code) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.airbnbPrimary)
            } else {
                Text(code.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.airbnbPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .allowsTightening(true)
                    .frame(width: 20, height: 20, alignment: .center)
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }
}

// MARK: - Income
struct IncomeListView: View {
    @StateObject private var vm: IncomeController
    @State private var navCollapsed = false
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var tabCommands: TabCommandCenter
    @EnvironmentObject private var lookup: LookupStore
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"
    @State private var showFilterSheet = false
    @State private var pendingDelete: Income? = nil
    @State private var pendingEdit: Income? = nil
    @State private var showCreateSheet = false
    @State private var showReportsModal = false
    // Micro-interactions for toolbar button
    @State private var breathe = false
    @State private var rippleTrigger = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(userId: Int) {
        _vm = StateObject(wrappedValue: IncomeController(userId: userId))
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
                                value: geo.frame(in: .named("incomeScroll")).minY)
                        }
                        .frame(height: 0)
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            let activeCount =
                                vm.selectedTypes.count + vm.selectedTags.count
                                + vm.selectedFYs.count + vm.selectedYears.count
                            let useFiltered = activeCount > 0
                            Group {
                                if vm.isLoading && vm.incomes.isEmpty {
                                    SummaryCard.placeholder()
                                } else {
                                    SummaryCard(
                                        totalAll: useFiltered ? vm.filteredTotalAll : vm.totalAll,
                                        totalNet: useFiltered ? vm.filteredTotalNet : vm.totalNet,
                                        totalTax: useFiltered ? vm.filteredTotalTax : vm.totalTaxPaid,
                                        currency: defaultCurrencyCode.uppercased()
                                    )
                                }
                            }
                            .padding(.top, 8)
                            HStack(spacing: 8) {
                                // Group-by control
                                Menu {
                                    Picker("Group by", selection: $vm.grouping) {
                                        ForEach(IncomeController.Grouping.allCases) { g in
                                            Text(g.title).tag(g)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.grid.2x2")
                                        Text(vm.grouping.title)
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.airbnbPrimary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Capsule().fill(Color.airbnbPrimary.opacity(0.12)))
                                }

                                // Filters button
                                Button {
                                    showFilterSheet = true
                                    Haptics.selection()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(
                                            systemName: activeCount == 0
                                                ? "line.3.horizontal.decrease.circle"
                                                : "line.3.horizontal.decrease.circle.fill")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.airbnbPrimary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Capsule().fill(Color.airbnbPrimary.opacity(0.12)))
                                }
                                .buttonStyle(PressableButtonStyle())

                                Spacer(minLength: 0)

                                // Clear button moved to the far right
                                if activeCount > 0 {
                                    Button {
                                        withAnimation(.snappy) {
                                            vm.selectedTypes.removeAll()
                                            vm.selectedTags.removeAll()
                                            vm.selectedFYs.removeAll()
                                            vm.selectedYears.removeAll()
                                        }
                                        Haptics.selection()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "xmark.circle.fill").font(
                                                .subheadline)
                                            Text("Clear").font(.subheadline.weight(.semibold))
                                        }
                                        .foregroundColor(.airbnbPrimary)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            Capsule().fill(Color.airbnbPrimary.opacity(0.12)))
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                }
                            }
                            if activeCount > 0 {
                                let sourcesText = vm.selectedTypes.sorted().joined(separator: ", ")
                                let tagsText = vm.selectedTags.sorted().joined(separator: ", ")
                                let fysText = vm.selectedFYs.sorted { $0.startYear > $1.startYear }
                                    .map { $0.title }.joined(separator: ", ")
                                let yearsText = vm.selectedYears.sorted(by: >).map(String.init)
                                    .joined(separator: ", ")
                                let parts = [
                                    sourcesText.isEmpty ? nil : "Source: \(sourcesText)",
                                    tagsText.isEmpty ? nil : "Tag: \(tagsText)",
                                    fysText.isEmpty ? nil : "FY: \(fysText)",
                                    yearsText.isEmpty ? nil : "Year: \(yearsText)",
                                ].compactMap { $0 }
                                Text(parts.joined(separator: "  ·  "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if vm.isLoading && vm.incomes.isEmpty {
                                ForEach(0..<5, id: \.self) { index in
                                    IncomeRowCard.placeholder()
                                }
                            } else if vm.sections.isEmpty {
                                EmptyStateCard(text: "No income records yet")
                            } else {
                                ForEach(vm.sections) { section in
                                    let sectionTotal = section.items.reduce(0) { $0 + $1.netAmount + $1.taxPaid }
                                    Section {
                                        ForEach(section.items, id: \.self) { item in
                                            IncomeRowCard(income: item, currency: defaultCurrencyCode.uppercased())
                                                .contentShape(Rectangle())
                                                .contextMenu {
                                                    Button {
                                                        Haptics.selection()
                                                        pendingEdit = item
                                                    } label: {
                                                        Label("Modify", systemImage: "pencil")
                                                    }
                                                    Button(role: .destructive) {
                                                        Haptics.selection()
                                                        pendingDelete = item
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                        }
                                    } header: {
                                        SectionHeader(
                                            grouping: vm.grouping,
                                            rawTitle: section.title,
                                            count: section.items.count,
                                            total: sectionTotal,
                                            currency: defaultCurrencyCode.uppercased()
                                        )
                                    }
                                }
                            }
                            // Bottom anchor for scroll-to-bottom
                            Color.clear.frame(height: LayoutConstants.tabBarHeight + 24).id("incomeBottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, LayoutConstants.tabBarHeight + 24)
                    }
                    .refreshable { await vm.refresh() }
                    .background(ScrollToTopEnabler())
                    .scrollIndicators(.hidden)
                    .coordinateSpace(name: "incomeScroll")
                }
                .onChange(of: tabCommands.scrollToBottomRequest) { _, req in
                    guard req == .income else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo("incomeBottom", anchor: .bottom)
                    }
                    DispatchQueue.main.async { tabCommands.scrollToBottomRequest = nil }
                }
                .fabOverlay(icon: "plus", accessibilityLabel: "Add income") {
                    showCreateSheet = true
                    Haptics.selection()
                }
            }
            .navigationTitle("Incomes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { trendToolbarButton }
            }
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
        }
        .task {
            vm.attachStore(lookup)
            // Only load if store doesn't have data and isn't loading
            if lookup.incomes.isEmpty && !lookup.isLoadingIncomes {
                await vm.load()
            }
        }
        .onChange(of: tabCommands.presentCreate) { _, req in
            guard req == .income else { return }
            showCreateSheet = true
            DispatchQueue.main.async { tabCommands.presentCreate = nil }
        }
        .onAppear {
            if tabCommands.presentCreate == .income {
                showCreateSheet = true
                DispatchQueue.main.async { tabCommands.presentCreate = nil }
            }
        }
        // Remove extra bottom safe-area inset; consistent FAB padding handles spacing
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.incomes)
        .animation(.easeInOut(duration: 0.2), value: vm.selectedTypes)
        .animation(.easeInOut(duration: 0.2), value: vm.grouping)
        .onChange(of: vm.errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            // Suppress banners for pull-to-refresh if we already have data
            guard vm.incomes.isEmpty else { return }
            banners.showError(
                message: message, retryTitle: "Retry", retry: { Task { await vm.refresh() } })
        }
        .sheet(isPresented: $showFilterSheet) {
            NavigationStack {
                IncomeFilterSheet(
                    types: vm.uniqueTypes,
                    tags: vm.uniqueTags,
                    years: vm.availableYears,
                    fys: vm.availableFYs,
                    selectedTypes: $vm.selectedTypes,
                    selectedTags: $vm.selectedTags,
                    selectedYears: $vm.selectedYears,
                    selectedFYs: $vm.selectedFYs,
                    onDone: { showFilterSheet = false },
                    onClear: {
                        vm.selectedTypes.removeAll()
                        vm.selectedTags.removeAll()
                        vm.selectedYears.removeAll()
                        vm.selectedFYs.removeAll()
                    }
                )
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showFilterSheet = false }
                    }
                }
                .toolbarBackground(Color.canvasBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert(item: $pendingDelete) { income in
            Alert(
                title: Text("Delete income?"),
                message: Text("This will permanently remove the record."),
                primaryButton: .destructive(Text("Delete"), action: { deleteIncome(income) }),
                secondaryButton: .cancel()
            )
        }
        // Create Income sheet
        .sheet(isPresented: $showCreateSheet) {
            NavigationStack {
                CreateIncomeView(userId: vm.userId)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        // Edit Income sheet
        .sheet(item: $pendingEdit) { income in
            NavigationStack {
                CreateIncomeView(userId: vm.userId, existing: income)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .fullScreenCover(isPresented: $showReportsModal) {
            NavigationStack {
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        Color.canvasBackground.ignoresSafeArea()
                        AssetOverviewCard(
                            preselect: (
                                type: .other,
                                id: 0,
                                name: "Income"
                            ),
                            otherChart: .income,
                            userId: vm.userId,
                            incomeFilters: (
                                types: vm.selectedTypes,
                                tags: vm.selectedTags,
                                years: vm.selectedYears,
                                fys: vm.selectedFYs
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
}

extension IncomeListView {
    fileprivate func deleteIncome(_ income: Income) {
        Task {
            let ok = await vm.delete(income)
            if ok {
                Haptics.success()
            } else {
                Haptics.softImpact()
                let msg = vm.errorMessage ?? "Failed to delete income."
                banners.showError(
                    message: msg, retryTitle: "Retry", retry: { Task { await vm.refresh() } })
            }
        }
    }
}

// Tinted mini stat (Airbnb style): subtle background with tinted text
// MiniStat removed; chips replaced with labeled lines to show full values


// MARK: - Summary Card (totals at top of Income screens)
private struct SummaryCard: View {
    let totalAll: Double
    let totalNet: Double
    let totalTax: Double
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total income")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(totalAll, format: .currency(code: currency))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.45), value: totalAll)
            }
            ViewThatFits(in: .horizontal) {
                // Preferred: pills side-by-side
                HStack(spacing: 8) {
                    let netPct: String? = totalAll > 0 ? (totalNet / totalAll).formatted(.percent.precision(.fractionLength(1))) : nil
                    let taxPct: String? = totalAll > 0 ? (totalTax / totalAll).formatted(.percent.precision(.fractionLength(1))) : nil
                    LabeledCurrencyPill(
                        title: "Net income",
                        value: totalNet,
                        currency: currency,
                        tint: .airbnbSuccess,
                        percent: netPct
                    )
                    LabeledCurrencyPill(
                        title: "Tax paid",
                        value: totalTax,
                        currency: currency,
                        tint: .airbnbPrimary,
                        percent: taxPct
                    )
                    Spacer(minLength: 0)
                }
                // Fallback: stack vertically when space is tight
                VStack(alignment: .leading, spacing: 8) {
                    let netPct: String? = totalAll > 0 ? (totalNet / totalAll).formatted(.percent.precision(.fractionLength(1))) : nil
                    let taxPct: String? = totalAll > 0 ? (totalTax / totalAll).formatted(.percent.precision(.fractionLength(1))) : nil
                    LabeledCurrencyPill(
                        title: "Net income",
                        value: totalNet,
                        currency: currency,
                        tint: .airbnbSuccess,
                        percent: netPct
                    )
                    LabeledCurrencyPill(
                        title: "Tax paid",
                        value: totalTax,
                        currency: currency,
                        tint: .airbnbPrimary,
                        percent: taxPct
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
        .accessibilityElement(children: .combine)
    }
    
    // Shimmer placeholder version
    static func placeholder() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ShimmerBlock(width: 100, height: 16, cornerRadius: 4)
            ShimmerBlock(width: 220, height: 34, cornerRadius: 6)
            HStack(spacing: 8) {
                ShimmerBlock(width: 140, height: 32, cornerRadius: 16)
                ShimmerBlock(width: 120, height: 32, cornerRadius: 16)
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }
}

// Trend/Sparkline removed per new design

// Local StatPill removed in favor of shared LabeledCurrencyPill

private struct IncomeSectionsList: View {
    let sections: [IncomeController.Section]
    let grouping: IncomeController.Grouping
    let currency: String
    var onEdit: (Income) -> Void
    var onLongPress: (Income) -> Void
    var body: some View {
        Group {
            ForEach(sections) { section in
                let sectionTotal = section.items.reduce(0) { $0 + $1.netAmount + $1.taxPaid }
                Section {
                    ForEach(section.items, id: \.self) { item in
                        IncomeRowCard(income: item, currency: currency)
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button {
                                    Haptics.selection()
                                    onEdit(item)
                                } label: {
                                    Label("Modify", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    Haptics.selection()
                                    onLongPress(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    SectionHeader(
                        grouping: grouping,
                        rawTitle: section.title,
                        count: section.items.count,
                        total: sectionTotal,
                        currency: currency
                    )
                }
            }
        }
    }
}

private struct SectionHeader: View {
    let grouping: IncomeController.Grouping
    let rawTitle: String
    let count: Int
    let total: Double
    let currency: String

    private var iconName: String {
        switch grouping {
        case .month: return "calendar"
        case .year: return "calendar"
        case .fy: return "calendar"
        case .tag: return "tag"
        case .source: return "square.grid.2x2"
        }
    }
    // Grouping badge removed to avoid redundancy with icon and title

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Capsule().fill(Color.airbnbPrimary.opacity(0.12)).frame(width: 32, height: 22)
                Image(systemName: iconName)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.airbnbPrimary)
            }
            Text(rawTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            Text(CurrencyShort.shortString(total, currency: currency))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .monospacedDigit()
            Text("\(count)")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(Capsule(style: .continuous).fill(Color.elevatedBackground))
                .overlay(Capsule(style: .continuous).stroke(Color.subtleSeparator, lineWidth: 1))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .fill(Color.elevatedBackgroundAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .fill(Color.airbnbPrimary)
                .frame(width: 4)
                .padding(.vertical, 6)
        }
        .zIndex(1)
    }
}

private struct IncomeRowCard: View {
    let income: Income
    let currency: String
    @EnvironmentObject private var lookup: LookupStore

    var body: some View {
        Button {
            Haptics.softImpact()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tagName)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(
                        "\(sourceName) • \(DateFormatter.dayMonYear.string(from: income.creditedDate))"
                    )
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
                Spacer(minLength: 8)
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("Total").font(.caption2.bold()).foregroundColor(.secondary)
                            Text(income.netAmount + income.taxPaid, format: .currency(code: currency))
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .allowsTightening(true)
                        }
                        VStack(alignment: .trailing, spacing: 6) {
                            HStack(spacing: 6) {
                                let total = income.netAmount + income.taxPaid
                                let netPct: String? = total > 0 ? (income.netAmount / total).formatted(.percent.precision(.fractionLength(1))) : nil
                                Text("Net").font(.caption2.bold()).lineLimit(1)
                                Text(income.netAmount, format: .currency(code: currency))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .allowsTightening(true)
                                if let p = netPct {
                                    Text("•").font(.caption2.weight(.bold))
                                    Text(p)
                                        .font(.caption2.weight(.semibold))
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .allowsTightening(true)
                                }
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .allowsTightening(true)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundColor(.airbnbSuccess)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                Capsule(style: .continuous).fill(Color.airbnbSuccess.opacity(0.12))
                            )
                            HStack(spacing: 6) {
                                let total = income.netAmount + income.taxPaid
                                let taxPct: String? = total > 0 ? (income.taxPaid / total).formatted(.percent.precision(.fractionLength(1))) : nil
                                Text("Tax").font(.caption2.bold()).lineLimit(1)
                                Text(income.taxPaid, format: .currency(code: currency))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .allowsTightening(true)
                                if let p = taxPct {
                                    Text("•").font(.caption2.weight(.bold))
                                    Text(p)
                                        .font(.caption2.weight(.semibold))
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .allowsTightening(true)
                                }
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .allowsTightening(true)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundColor(.airbnbPrimary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                Capsule(style: .continuous).fill(Color.airbnbPrimary.opacity(0.12))
                            )
                        }
                        .layoutPriority(1)
                    }
                    // Chevron removed per design
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.elevatedBackground)
            )
            .elevatedShadow()
        }
        .buttonStyle(PressableButtonStyle())
        .transition(.moveAndFade)
    }
    
    private var sourceName: String {
        lookup.incomeSources.first { $0.id == income.incomeSourceId }?.name ?? "Unknown Source"
    }
    
    private var tagName: String {
        lookup.incomeTags.first { $0.id == income.incomeTagId }?.name ?? "Unknown Tag"
    }
}

extension IncomeRowCard {
    fileprivate static func placeholder() -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                ShimmerBlock(width: 120, height: 16, cornerRadius: 4)
                ShimmerBlock(width: 180, height: 14, cornerRadius: 4)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                ShimmerBlock(width: 120, height: 18, cornerRadius: 4)  // Total
                ShimmerBlock(width: 90, height: 14, cornerRadius: 4)   // Net
                ShimmerBlock(width: 80, height: 14, cornerRadius: 4)   // Tax
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }
}

// MARK: - Create Income
struct CreateIncomeView: View {
    let userId: Int
    let existing: Income?
    @EnvironmentObject private var lookup: LookupStore
    @EnvironmentObject private var banners: BannerCenter
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"

    @State private var amountText: String = ""
    @State private var taxText: String = ""
    @State private var creditedDate: Date = Date()
    @State private var currencyCode: String = "INR"
    @State private var selectedSource: IncomeSource? = nil
    @State private var selectedTag: IncomeTag? = nil
    @State private var saving: Bool = false
    @State private var showCurrencyPicker: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showTypePicker: Bool = false
    @State private var showTagPicker: Bool = false

    private let client = RestClient()

    init(userId: Int, existing: Income? = nil) {
        self.userId = userId
        self.existing = existing
    }

    // MARK: - Validation
    private var amount: Double? {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(
            in: .whitespacesAndNewlines)
        return Double(normalized)
    }
    private var tax: Double? {
        let normalized = taxText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(
            in: .whitespacesAndNewlines)
        return Double(normalized) ?? 0
    }
    private var isValid: Bool {
        guard let amount = amount, amount >= 0 else { return false }
        guard let tax = tax, tax >= 0 else { return false }
        guard selectedSource != nil, selectedTag != nil else { return false }
        return true
    }
    private var totalAll: Double { (amount ?? 0) + (tax ?? 0) }
    private var confirmTitle: String {
        if existing == nil {
            return saving ? "Saving…" : "Save"
        } else {
            return saving ? "Updating…" : "Update"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary card
                SummaryCard(
                    totalAll: totalAll,
                    totalNet: amount ?? 0,
                    totalTax: tax ?? 0,
                    currency: currencyCode
                )

                // Amount inputs
                SettingsGroup(title: "Amount", showHeader: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            TextField("Net amount", text: $amountText)
                                .keyboardType(.decimalPad)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .onChange(of: amountText) { _, newVal in
                                    amountText = sanitizeDecimalInput(newVal)
                                }
                            Spacer(minLength: 8)
                            Text(currencyCode.uppercased())
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                        Rectangle().fill(Color.subtleSeparator).frame(height: 0.5)
                        HStack(spacing: 12) {
                            TextField("Tax paid", text: $taxText)
                                .keyboardType(.decimalPad)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .onChange(of: taxText) { _, newVal in
                                    taxText = sanitizeDecimalInput(newVal)
                                }
                            Spacer(minLength: 8)
                            Text(currencyCode.uppercased())
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                        if let amt = amount, amt < 0 {
                            Text("Amount must be non‑negative").font(.footnote).foregroundColor(
                                .airbnbPrimary)
                        }
                        if let t = tax, t < 0 {
                            Text("Tax must be non‑negative").font(.footnote).foregroundColor(
                                .airbnbPrimary)
                        }
                    }
                }

                // Details (date, currency)
                SettingsGroup(title: "Details") {
                    VStack(spacing: 0) {
                        // Date (sheet)
                        Button {
                            showDatePicker = true
                            Haptics.selection()
                        } label: {
                            SettingsCell(
                                icon: "calendar", title: "Credited on",
                                subtitle: DateFormatter.dayMonYear.string(from: creditedDate)
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(
                            .horizontal, 12)
                        // Currency (sheet)
                        Button {
                            showCurrencyPicker = true
                            Haptics.selection()
                        } label: {
                            SettingsCell(
                                title: "Currency",
                                subtitle: CurrencyCatalog.byCode[currencyCode.uppercased()]?.name
                                    ?? currencyCode,
                                leading: {
                                    CurrencyBadge(code: currencyCode)
                                }
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Categorize (source, tag)
                SettingsGroup(title: "Categorize") {
                    VStack(spacing: 0) {
                        // Source (sheet)
                        Button {
                            showTypePicker = true
                            Haptics.selection()
                        } label: {
                            SettingsCell(
                                icon: "creditcard", title: "Source",
                                subtitle: selectedSource?.name ?? "Not set"
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(
                            .horizontal, 12)
                        // Tag (sheet)
                        Button {
                            showTagPicker = true
                            Haptics.selection()
                        } label: {
                            SettingsCell(
                                icon: "tag", title: "Tag", subtitle: selectedTag?.name ?? "Not set"
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, LayoutConstants.tabBarHeight + 24)
        }
        .background(ScrollToTopEnabler())
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle(existing == nil ? "New income" : "Edit income")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(confirmTitle) { Task { await save() } }
                    .disabled(!isValid || saving)
            }
        }
        .toolbarBackground(Color.canvasBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            Task {
                await lookup.loadIncomeSourcesIfNeeded(userId: userId)
                await lookup.loadIncomeTagsIfNeeded(userId: userId)
                bootstrapDefaults()
            }
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selectedCode: $currencyCode)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePickerSheet(selectedDate: $creditedDate)
                    .navigationTitle("Select date")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTypePicker) {
            NamedEntityPickerSheet<IncomeSource>(
                title: "Select source", items: lookup.incomeSources, icon: "creditcard",
                selected: $selectedSource
            )
        }
        .sheet(isPresented: $showTagPicker) {
            NamedEntityPickerSheet<IncomeTag>(
                title: "Select tag", items: lookup.incomeTags, icon: "tag",
                selected: $selectedTag
            )
        }
    }

    private func bootstrapDefaults() {
        if let ex = existing {
            amountText = String(format: "%.2f", ex.netAmount)
            taxText = String(format: "%.2f", ex.taxPaid)
            creditedDate = ex.creditedDate
            currencyCode = ex.currency.uppercased()
            selectedSource = lookup.incomeSources.first { $0.id == ex.incomeSourceId }
            selectedTag = lookup.incomeTags.first { $0.id == ex.incomeTagId }
            return
        }
        currencyCode = defaultCurrencyCode.uppercased()
        if selectedSource == nil {
            selectedSource =
                lookup.incomeSources.first(where: { $0.isDefault }) ?? lookup.incomeSources.first
        }
        if selectedTag == nil {
            selectedTag =
                lookup.incomeTags.first(where: { $0.isDefault }) ?? lookup.incomeTags.first
        }
    }

    private func save() async {
        guard isValid, let amount = amount, let tax = tax, let source = selectedSource,
            let tag = selectedTag
        else { return }
        await MainActor.run { saving = true }
        do {
            if let ex = existing {
                _ = try await client.updateIncome(
                    id: ex.id,
                    incomeSourceId: source.id,
                    incomeTagId: tag.id,
                    netAmount: amount,
                    taxPaid: tax,
                    creditedDate: creditedDate,
                    currency: currencyCode
                )
            } else {
                _ = try await client.createIncome(
                    userId: userId,
                    incomeSourceId: source.id,
                    incomeTagId: tag.id,
                    netAmount: amount,
                    taxPaid: tax,
                    creditedDate: creditedDate,
                    currency: currencyCode
                )
            }
            Haptics.success()
            await lookup.refreshIncomes(userId: userId)
            await MainActor.run { dismiss() }
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? error.localizedDescription
            await MainActor.run { 
                banners.showError(message: msg)
                // For duplicate income errors (409), close the sheet after showing error
                if let apiError = error as? APIError,
                   case .apiError(let status, _) = apiError,
                   status == 409 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        dismiss()
                    }
                }
            }
        }
        await MainActor.run { saving = false }
    }
}

// Shared CurrencyPickerSheet is used instead (in Views/Shared/CurrencyPickerSheet.swift)

// MARK: - Input sanitization (numbers with up to 2 decimals)
private func sanitizeDecimalInput(_ input: String) -> String {
    let s = input.replacingOccurrences(of: ",", with: ".")
    // Keep only digits and the first dot
    var result = ""
    var hasDot = false
    for ch in s {
        if ch.isNumber {
            result.append(ch)
        } else if ch == "." && !hasDot {
            result.append(ch)
            hasDot = true
        }
    }
    if result == "." { result = "0." }
    // Limit to 2 decimals
    if let dotIdx = result.firstIndex(of: ".") {
        let after = result[result.index(after: dotIdx)...]
        let limited = String(after.prefix(2))
        result = String(result[..<result.index(after: dotIdx)]) + limited
    }
    // Trim leading zeros for integer part (keep one zero)
    if let dotIdx = result.firstIndex(of: ".") {
        var intPart = String(result[..<dotIdx])
        while intPart.count > 1 && intPart.first == "0" { intPart.removeFirst() }
        result = intPart + String(result[dotIdx...])
    } else {
        while result.count > 1 && result.first == "0" { result.removeFirst() }
    }
    return result
}

// MARK: - Date Picker Sheet (Airbnb style)
private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 16) {
            SettingsGroup(showHeader: false) {
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker(
                        "Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color.canvasBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
        .toolbarBackground(Color.canvasBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// Shared NamedEntityPickerSheet is used instead (in Views/Shared/NamedEntityPickerSheet.swift)
