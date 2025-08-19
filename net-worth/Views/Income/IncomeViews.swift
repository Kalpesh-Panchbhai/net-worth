import SwiftUI

// MARK: - Income
struct IncomeListView: View {
    @StateObject private var vm: IncomeController
    @State private var navCollapsed = false
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var tabCommands: TabCommandCenter
    @State private var showFilterSheet = false
    @State private var pendingDelete: Income? = nil

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
                                currency: vm.displayCurrency
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
                                        Image(systemName: activeCount == 0 ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
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
                                    IncomeRowCard.placeholder()
                                }
                                .shimmer()
                            } else if vm.sections.isEmpty {
                                EmptyStateCard(text: "No income records yet")
                            } else {
                                IncomeSectionsList(
                                    sections: vm.sections,
                                    grouping: vm.grouping,
                                    onLongPress: { item in pendingDelete = item }
                                )
                            }
                            // Bottom anchor for scroll-to-bottom
                            Color.clear.frame(height: 1).id("incomeBottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
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
            .fabOverlay(accessibilityLabel: "Add income") { Haptics.softImpact() }
            .navigationTitle("Incomes")
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
        }
        .task { await vm.load() }
        .refreshable { await vm.refresh() }
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
    }
}

private extension IncomeListView {
    func deleteIncome(_ income: Income) {
        Task {
            let ok = await vm.delete(income)
            if ok {
                Haptics.success()
            } else {
                Haptics.softImpact()
                let msg = vm.errorMessage ?? "Failed to delete income."
                banners.showError(message: msg, retryTitle: "Retry", retry: { Task { await vm.refresh() } })
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
                StatPill(title: "Net income", value: totalNet, currency: currency, tint: .airbnbSuccess)
                StatPill(title: "Tax paid", value: totalTax, currency: currency, tint: .airbnbPrimary)
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

private struct StatPill: View {
    let title: String
    let value: Double
    let currency: String
    var tint: Color = .airbnbPrimary
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value, format: .currency(code: currency))
                .font(.headline)
                .foregroundColor(tint)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.45), value: value)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.08))
        )
    }
}

private struct IncomeSectionsList: View {
    let sections: [IncomeController.Section]
    let grouping: IncomeController.Grouping
    var onLongPress: (Income) -> Void
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(sections) { section in
                SectionHeader(grouping: grouping, rawTitle: section.title, count: section.items.count)
                    .padding(.top, 8)
                ForEach(section.items, id: \.id) { item in
                    IncomeRowCard(income: item)
                        .contentShape(Rectangle())
                        .contextMenu {
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
                            Text(income.amount + income.taxPaid, format: .currency(code: income.currency))
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
                                Text(income.amount, format: .currency(code: income.currency))
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
                                Text(income.taxPaid, format: .currency(code: income.currency))
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
                    width: 120, height: 18) // Total
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                    width: 90, height: 14) // Net
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                    width: 80, height: 14) // Tax
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

// Sparkline removed per new design

// FloatingAddButton moved to Shared/FloatingActionButton.swift

// MARK: - Cards
private struct EmptyStateCard: View {
    let text: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray").font(.largeTitle).foregroundColor(.secondary)
            Text(text).font(.headline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }
}
