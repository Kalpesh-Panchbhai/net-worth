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
                        VStack(spacing: 16) {
                            let activeCount =
                                vm.selectedTypes.count + vm.selectedTags.count
                                + vm.selectedFYs.count + vm.selectedYears.count
                            let useFiltered = activeCount > 0
                            SummaryCard(
                                totalAll: useFiltered ? vm.filteredTotalAll : vm.totalAll,
                                totalNet: useFiltered ? vm.filteredTotalNet : vm.totalNet,
                                totalTax: useFiltered ? vm.filteredTotalTax : vm.totalTaxPaid,
                                currency: defaultCurrencyCode.uppercased()
                            )
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
                                ForEach(0..<5, id: \.self) { _ in
                                    IncomeRowCard.placeholder().shimmer()
                                }
                            } else if vm.sections.isEmpty {
                                EmptyStateCard(text: "No income records yet")
                            } else {
                                IncomeSectionsList(
                                    sections: vm.sections,
                                    grouping: vm.grouping,
                                    currency: defaultCurrencyCode.uppercased(),
                                    onEdit: { item in pendingEdit = item },
                                    onLongPress: { item in pendingDelete = item }
                                )
                            }
                            // Bottom anchor for scroll-to-bottom (no FAB on this screen)
                            Color.clear.frame(height: LayoutConstants.tabBarHeight + 24).id(
                                "incomeBottom")
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
            }
            .navigationTitle("Incomes")
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
        }
        .task {
            vm.attachStore(lookup)
            await vm.load()
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 66) }
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
                FilterSheet(
                    types: vm.uniqueTypes,
                    tags: vm.uniqueTags,
                    years: vm.availableYears,
                    fys: vm.availableFYs,
                    selectedTypes: $vm.selectedTypes,
                    selectedTags: $vm.selectedTags,
                    selectedYears: $vm.selectedYears,
                    selectedFYs: $vm.selectedFYs
                ) {
                    showFilterSheet = false
                } onClear: {
                    vm.selectedTypes.removeAll()
                    vm.selectedTags.removeAll()
                    vm.selectedYears.removeAll()
                    vm.selectedFYs.removeAll()
                }
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
        // Floating action button to add new income
        .fabOverlay(icon: "plus", accessibilityLabel: "Add income") {
            showCreateSheet = true
            Haptics.selection()
        }
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

// MARK: - Filter Sheet
private struct FilterSheet: View {
    let types: [String]
    let tags: [String]
    let years: [Int]
    let fys: [IncomeController.FinancialYear]
    @Binding var selectedTypes: Set<String>
    @Binding var selectedTags: Set<String>
    @Binding var selectedYears: Set<Int>
    @Binding var selectedFYs: Set<IncomeController.FinancialYear>
    var onClose: () -> Void
    var onClear: () -> Void
    @State private var query: String = ""
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Source") {
                    let filtered = types.filter {
                        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? true : $0.localizedCaseInsensitiveContains(query)
                    }
                    ForEach(filtered, id: \.self) { t in
                        Button {
                            withAnimation(.snappy) {
                                if selectedTypes.contains(t) {
                                    selectedTypes.remove(t)
                                } else {
                                    selectedTypes.insert(t)
                                }
                            }
                            Haptics.selection()
                        } label: {
                            HStack {
                                Text(t)
                                Spacer()
                                if selectedTypes.contains(t) {
                                    Image(systemName: "checkmark").foregroundColor(.airbnbPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                Section("Tag") {
                    let tagsFiltered = tags.filter {
                        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? true : $0.localizedCaseInsensitiveContains(query)
                    }
                    ForEach(tagsFiltered, id: \.self) { tag in
                        Button {
                            withAnimation(.snappy) {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                            Haptics.selection()
                        } label: {
                            HStack {
                                Text(tag)
                                Spacer()
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark").foregroundColor(.airbnbPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                Section("Financial year") {
                    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
                    let fysFiltered = fys.filter { fy in
                        q.isEmpty ? true : fy.title.localizedCaseInsensitiveContains(q)
                    }
                    ForEach(fysFiltered) { fy in
                        Button {
                            withAnimation(.snappy) {
                                // Tapping toggles FY; Years set is independent. Keep both multi-select.
                                if selectedFYs.contains(fy) {
                                    selectedFYs.remove(fy)
                                } else {
                                    selectedFYs.insert(fy)
                                }
                            }
                            Haptics.selection()
                        } label: {
                            HStack {
                                Text(fy.title)
                                Spacer()
                                if selectedFYs.contains(fy) {
                                    Image(systemName: "checkmark").foregroundColor(.airbnbPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                Section("Year") {
                    let yearsFiltered = years.filter {
                        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? true : String($0).localizedCaseInsensitiveContains(query)
                    }
                    ForEach(yearsFiltered, id: \.self) { y in
                        Button {
                            withAnimation(.snappy) {
                                if selectedYears.contains(y) {
                                    selectedYears.remove(y)
                                } else {
                                    selectedYears.insert(y)
                                }
                            }
                            Haptics.selection()
                        } label: {
                            HStack {
                                Text(String(y))
                                Spacer()
                                if selectedYears.contains(y) {
                                    Image(systemName: "checkmark").foregroundColor(.airbnbPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.canvasBackground)
            HStack(spacing: 12) {
                Button(action: {
                    onClear()
                    onClose()
                }) {
                    Text("Clear filters").bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.elevatedBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.subtleSeparator, lineWidth: 1)
                        )
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(16)
            .background(Color.canvasBackground.ignoresSafeArea(edges: .bottom))
        }
    }
}
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
                    .foregroundStyle(LinearGradient.airbnbAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.45), value: totalAll)
            }
            HStack(spacing: 8) {
                LabeledCurrencyPill(
                    title: "Net income", value: totalNet, currency: currency, tint: .airbnbSuccess)
                LabeledCurrencyPill(
                    title: "Tax paid", value: totalTax, currency: currency, tint: .airbnbPrimary)
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
        .accessibilityElement(children: .combine)
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
        LazyVStack(spacing: 12) {
            ForEach(sections) { section in
                SectionHeader(
                    grouping: grouping, rawTitle: section.title, count: section.items.count
                )
                .padding(.top, 8)
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
            }
        }
    }
}

private struct SectionHeader: View {
    let grouping: IncomeController.Grouping
    let rawTitle: String
    let count: Int

    private var iconName: String {
        switch grouping {
        case .month: return "calendar"
        case .year: return "calendar"
        case .fy: return "calendar"
        case .tag: return "tag"
        case .source: return "square.grid.2x2"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.airbnbPrimary.opacity(0.12))
                    .frame(width: 26, height: 26)
                Image(systemName: iconName)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.airbnbPrimary)
            }
            Text(rawTitle)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Text("\(count)")
                .font(.caption2.bold())
                .foregroundColor(.airbnbPrimary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.airbnbPrimary.opacity(0.12))
                )
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 6)
    }
}

private struct IncomeRowCard: View {
    let income: Income
    let currency: String

    var body: some View {
        Button {
            Haptics.softImpact()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(income.incomeTag.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(
                        "\(income.incomeType.name) • \(DateFormatter.dayMonYear.string(from: income.creditedDate))"
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
                            Text(income.amount + income.taxPaid, format: .currency(code: currency))
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.primary)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .allowsTightening(true)
                        }
                        VStack(alignment: .trailing, spacing: 6) {
                            HStack(spacing: 6) {
                                Text("Net").font(.caption2.bold())
                                Text(income.amount, format: .currency(code: currency))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .allowsTightening(true)
                            }
                            .foregroundColor(.airbnbSuccess)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                Capsule(style: .continuous).fill(Color.airbnbSuccess.opacity(0.12))
                            )
                            HStack(spacing: 6) {
                                Text("Tax").font(.caption2.bold())
                                Text(income.taxPaid, format: .currency(code: currency))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .allowsTightening(true)
                            }
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
}

extension IncomeRowCard {
    fileprivate static func placeholder() -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                    width: 120, height: 16)
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                    width: 180, height: 14)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                    width: 120, height: 18)  // Total
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                    width: 90, height: 14)  // Net
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                    width: 80, height: 14)  // Tax
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
    @State private var selectedType: IncomeType? = nil
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
        guard selectedType != nil, selectedTag != nil else { return false }
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
                                subtitle: selectedType?.name ?? "Not set"
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
                await lookup.loadIncomeTypesIfNeeded(userId: userId)
                await lookup.loadIncomeTagsIfNeeded(userId: userId)
                bootstrapDefaults()
            }
        }
        .sheet(isPresented: $showCurrencyPicker) {
            NavigationStack {
                CurrencyPickerSheet(selectedCode: $currencyCode)
                    .navigationTitle("Select currency")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
            NavigationStack {
                EntityPickerSheet<IncomeType>(
                    title: "Select source", items: lookup.incomeTypes, icon: "creditcard",
                    selected: $selectedType
                )
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTagPicker) {
            NavigationStack {
                EntityPickerSheet<IncomeTag>(
                    title: "Select tag", items: lookup.incomeTags, icon: "tag",
                    selected: $selectedTag
                )
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func bootstrapDefaults() {
        if let ex = existing {
            amountText = String(format: "%.2f", ex.amount)
            taxText = String(format: "%.2f", ex.taxPaid)
            creditedDate = ex.creditedDate
            currencyCode = ex.currency.uppercased()
            selectedType = ex.incomeType
            selectedTag = ex.incomeTag
            return
        }
        currencyCode = defaultCurrencyCode.uppercased()
        if selectedType == nil {
            selectedType =
                lookup.incomeTypes.first(where: { $0.isDefault }) ?? lookup.incomeTypes.first
        }
        if selectedTag == nil {
            selectedTag =
                lookup.incomeTags.first(where: { $0.isDefault }) ?? lookup.incomeTags.first
        }
    }

    private func save() async {
        guard isValid, let amount = amount, let tax = tax, let type = selectedType,
            let tag = selectedTag
        else { return }
        await MainActor.run { saving = true }
        do {
            if let ex = existing {
                try await client.updateIncome(
                    id: ex.id,
                    userId: userId,
                    amount: amount,
                    taxPaid: tax,
                    creditedDate: creditedDate,
                    currency: currencyCode,
                    incomeType: type,
                    incomeTag: tag
                )
            } else {
                _ = try await client.createIncome(
                    userId: userId,
                    amount: amount,
                    taxPaid: tax,
                    creditedDate: creditedDate,
                    currency: currencyCode,
                    incomeType: type,
                    incomeTag: tag
                )
            }
            Haptics.success()
            await lookup.refreshIncomes(userId: userId)
            await MainActor.run { dismiss() }
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? error.localizedDescription
            await MainActor.run { banners.showError(message: msg) }
        }
        await MainActor.run { saving = false }
    }
}

// MARK: - Currency Picker Sheet
private struct CurrencyPickerSheet: View {
    @Binding var selectedCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    private var list: [Currency] {
        let base: [Currency]
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            base = CurrencyCatalog.all
        } else {
            base = CurrencyCatalog.all.filter { c in
                c.name.localizedCaseInsensitiveContains(q)
                    || c.code.localizedCaseInsensitiveContains(q)
                    || c.symbol.localizedCaseInsensitiveContains(q)
            }
        }
        // Pin selected to top
        let sel = selectedCode.uppercased()
        return base.sorted { a, b in
            let aSel = a.code.uppercased() == sel
            let bSel = b.code.uppercased() == sel
            if aSel != bSel { return aSel && !bSel }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingsGroup(showHeader: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(list.enumerated()), id: \.element) { idx, c in
                            row(c)
                            if idx < list.count - 1 {
                                Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(
                                    .horizontal, 12)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .searchable(
            text: $query, placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("Search currency"))
    }
    @ViewBuilder
    private func row(_ c: Currency) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.airbnbPrimary.opacity(0.12))
                Text(c.code)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.airbnbPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(c.name).font(.subheadline.weight(.semibold))
                Text(c.code).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if c.code.uppercased() == selectedCode.uppercased() {
                Text("Selected")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(LinearGradient.airbnbAccent))
                    .shadow(color: .airbnbPrimary.opacity(0.25), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCode = c.code
            Haptics.selection()
            dismiss()
        }
    }
}

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

// MARK: - Generic Entity Picker Sheet
private struct EntityPickerSheet<T: NamedEntity>: View {
    let title: String
    let items: [T]
    let icon: String
    @Binding var selected: T?
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    private var displayed: [T] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered =
            q.isEmpty ? items : items.filter { $0.name.localizedCaseInsensitiveContains(q) }
        // Default on top, name asc
        return filtered.sorted { a, b in
            if a.isDefault != b.isDefault { return a.isDefault && !b.isDefault }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingsGroup(showHeader: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(displayed.enumerated()), id: \.element) { idx, item in
                            row(item)
                            if idx < displayed.count - 1 {
                                Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(
                                    .horizontal, 12)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .searchable(
            text: $query, placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("Search")
        )
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.canvasBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    @ViewBuilder
    private func row(_ item: T) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.airbnbPrimary.opacity(0.12))
                Image(systemName: (selected?.id == item.id) ? filledIcon(icon) : icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.airbnbPrimary)
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline.weight(.semibold))
                if item.isDefault { Text("Default").font(.caption2).foregroundColor(.secondary) }
            }
            Spacer()
            if selected?.id == item.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(LinearGradient.airbnbAccent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            selected = item
            Haptics.selection()
            dismiss()
        }
    }

    // Use a filled variant of the SF Symbol when selected
    private func filledIcon(_ base: String) -> String {
        base.hasSuffix(".fill") ? base : base + ".fill"
    }
}
