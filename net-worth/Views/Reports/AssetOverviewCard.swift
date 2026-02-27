import Charts
import SwiftUI

// MARK: - Type Aliases
typealias FinancialYear = IncomeController.FinancialYear

// MARK: - Asset Overview Card (matches the attached design)
struct AssetOverviewCard: View {
    // MARK: - Types
    enum Range: String, CaseIterable, Identifiable {
        case oneMonth = "1m"
        case threeMonths = "3m"
        case sixMonths = "6m"
        case oneYear = "1y"
        case twoYears = "2y"
        case fiveYears = "5y"
        case all = "All"

        var id: String { rawValue }
        var title: String { rawValue.uppercased() }
    }

    // Convenience for current selection
    private var selectedEntity: (type: ChartEntityType, id: Int)? {
        if let t = entityType, let i = entityId { return (t, i) }
        return nil
    }

    struct Point: Identifiable, Hashable {
        let id: Int
        let date: Date
        let value: Double
        let invested: Double
        let averagePerMonth: Double?
        let taxPaid: Double
        let averageTaxPerMonth: Double?
    }

    // MARK: - State
    @State private var selectedRange: Range = .oneMonth
    @State private var selectedPoint: Point?
    @AppStorage("defaultCurrencyCode") private var currency: String = "INR"
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var rangeNS
    @State private var tooltipSize: CGSize = .zero
    @State private var isLoading: Bool = false
    // Data source selection (None by default)
    @State private var entityType: ChartEntityType? = nil
    @State private var entityId: Int? = nil
    @State private var otherChartType: OtherChartType? = nil
    @State private var selectedEntityName: String = "Choose source"
    @State private var showEntityPicker: Bool = false
    @State private var showIncomeFilterSheet = false
    @State private var userId: Int = 1  // TODO: Inject from app state / auth
    @EnvironmentObject private var lookup: LookupStore
    // Live data
    @State private var data: [Point] = []
    @State private var selectedTypes: Set<String> = []
    @State private var selectedTags: Set<String> = []
    @State private var selectedYears: Set<Int> = []
    @State private var selectedFYs: Set<FinancialYear> = []

    // Chart series visibility toggles for income charts
    @State private var showIncomeSeries: Bool = true
    @State private var showAvgIncomeSeries: Bool = true
    @State private var showTaxSeries: Bool = true
    @State private var showAvgTaxSeries: Bool = true

    // Init allowing caller to specify what to chart
    init(
        preselect: (type: ChartEntityType, id: Int, name: String)? = nil,
        otherChart: OtherChartType? = nil,
        userId: Int? = nil,
        incomeFilters: (
            types: Set<String>, tags: Set<String>, years: Set<Int>,
            fys: Set<IncomeController.FinancialYear>
        )? = nil
    ) {
        if let p = preselect {
            _entityType = State(initialValue: p.type)
            _entityId = State(initialValue: p.id)
            _selectedEntityName = State(initialValue: p.name)
        }
        if let oc = otherChart {
            _otherChartType = State(initialValue: oc)
        }
        if let uid = userId { _userId = State(initialValue: uid) }
        if let filters = incomeFilters {
            _selectedTypes = State(initialValue: filters.types)
            _selectedTags = State(initialValue: filters.tags)
            _selectedYears = State(initialValue: filters.years)
            _selectedFYs = State(initialValue: filters.fys)
        }
    }
    private var headlineValue: Double { data.last?.value ?? 0 }
    private var deltaPercent: Double {
        guard let firstPoint = data.first, let lastPoint = data.last else { return 0 }
        let newMoneyAdded = lastPoint.invested - firstPoint.invested
        let expectedValue = firstPoint.value + newMoneyAdded
        guard expectedValue > 0 else { return 0 }
        return ((lastPoint.value - expectedValue) / expectedValue) * 100
    }
    private var deltaAmount: Double {
        guard let firstPoint = data.first, let lastPoint = data.last else { return 0 }
        let newMoneyAdded = lastPoint.invested - firstPoint.invested
        let expectedValue = firstPoint.value + newMoneyAdded
        return lastPoint.value - expectedValue
    }

    // MARK: - Helper Properties
    private var isIncomeChart: Bool {
        return otherChartType == .income
    }

    private var filteredIncomes: [Income] {
        guard isIncomeChart else { return lookup.incomes }

        return lookup.incomes.filter { income in
            // Filter by types (income sources)
            if !selectedTypes.isEmpty {
                let sourceName =
                    lookup.incomeSources.first { $0.id == income.incomeSourceId }?.name ?? ""
                if !selectedTypes.contains(sourceName) {
                    return false
                }
            }

            // Filter by tags
            if !selectedTags.isEmpty {
                let tagName = lookup.incomeTags.first { $0.id == income.incomeTagId }?.name ?? ""
                if !selectedTags.contains(tagName) {
                    return false
                }
            }

            // Filter by years
            if !selectedYears.isEmpty {
                let year = Calendar.current.component(.year, from: income.creditedDate)
                if !selectedYears.contains(year) {
                    return false
                }
            }

            // Filter by financial years
            if !selectedFYs.isEmpty {
                let cal = Calendar.current
                let comp = cal.dateComponents([.year, .month], from: income.creditedDate)
                guard let y = comp.year, let m = comp.month else { return true }
                let startYear = m >= 4 ? y : (y - 1)
                let fy = IncomeController.FinancialYear(startYear: startYear)
                if !selectedFYs.contains(fy) {
                    return false
                }
            }

            return true
        }
    }

    private var uniqueTypes: [String] {
        let sourceIds = Set(lookup.incomes.map { $0.incomeSourceId })
        return lookup.incomeSources.filter { sourceIds.contains($0.id) }.map { $0.name }.sorted()
    }

    private var uniqueTags: [String] {
        let tagIds = Set(lookup.incomes.map { $0.incomeTagId })
        return lookup.incomeTags.filter { tagIds.contains($0.id) }.map { $0.name }.sorted()
    }

    private var availableYears: [Int] {
        let years = lookup.incomes.map { Calendar.current.component(.year, from: $0.creditedDate) }
        return Array(Set(years)).sorted(by: >)
    }

    private var availableFYs: [FinancialYear] {
        let cal = Calendar.current
        let startYears: [Int] = lookup.incomes.map { income in
            let comp = cal.dateComponents([.year, .month], from: income.creditedDate)
            guard let y = comp.year, let m = comp.month else { return 0 }
            return m >= 4 ? y : (y - 1)
        }
        let setYears = Set(startYears.filter { $0 > 0 })
        return setYears.map { IncomeController.FinancialYear(startYear: $0) }.sorted {
            $0.startYear > $1.startYear
        }
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            header
            entitySelectorBar
            if isIncomeChart {
                // Show applied filters like in Income view
                let activeCount =
                    selectedTypes.count + selectedTags.count + selectedYears.count
                    + selectedFYs.count
                if activeCount > 0 {
                    let sourcesText = selectedTypes.sorted().joined(separator: ", ")
                    let tagsText = selectedTags.sorted().joined(separator: ", ")
                    let fysText = selectedFYs.sorted { $0.startYear > $1.startYear }
                        .map { $0.title }.joined(separator: ", ")
                    let yearsText = selectedYears.sorted(by: >).map(String.init)
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
            }
            rangeSelector
            chart
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if isIncomeChart {
                chartLegend
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(16)
        .elevatedCardBackground(cornerRadius: 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showIncomeFilterSheet) {
            NavigationStack {
                IncomeFilterSheet(
                    types: uniqueTypes,
                    tags: uniqueTags,
                    years: availableYears,
                    fys: availableFYs,
                    selectedTypes: $selectedTypes,
                    selectedTags: $selectedTags,
                    selectedYears: $selectedYears,
                    selectedFYs: $selectedFYs,
                    onDone: {
                        showIncomeFilterSheet = false
                        reloadIncomeChart()
                    },
                    onClear: {
                        selectedTypes.removeAll()
                        selectedTags.removeAll()
                        selectedYears.removeAll()
                        selectedFYs.removeAll()
                    }
                )
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showIncomeFilterSheet = false }
                    }
                }
                .toolbarBackground(Color.canvasBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // Refresh chart immediately when filters change (even without changing range)
        .onChange(of: selectedTypes) { reloadIncomeChart() }
        .onChange(of: selectedTags) { reloadIncomeChart() }
        .onChange(of: selectedYears) { reloadIncomeChart() }
        .onChange(of: selectedFYs) { reloadIncomeChart() }
        .onAppear {
            if selectedEntity != nil {
                startLoading(to: selectedRange)
            }
        }
    }

    // MARK: - Chart Legend
    private var chartLegend: some View {
        HStack(spacing: 0) {
            // Income series toggle
            Button {
                withAnimation(.snappy) {
                    showIncomeSeries.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(showIncomeSeries ? Color.airbnbPrimary : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("Income")
                        .font(.caption.weight(.medium))
                        .foregroundColor(showIncomeSeries ? .primary : .secondary)
                        .strikethrough(!showIncomeSeries)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            // Avg Income series toggle
            Button {
                withAnimation(.snappy) {
                    showAvgIncomeSeries.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(showAvgIncomeSeries ? Color.orange : Color.secondary.opacity(0.3))
                        .frame(width: 12, height: 2)
                        .overlay(
                            Rectangle()
                                .fill(
                                    showAvgIncomeSeries
                                        ? Color.orange : Color.secondary.opacity(0.3)
                                )
                                .frame(width: 2, height: 2)
                                .offset(x: -3)
                        )
                        .overlay(
                            Rectangle()
                                .fill(
                                    showAvgIncomeSeries
                                        ? Color.orange : Color.secondary.opacity(0.3)
                                )
                                .frame(width: 2, height: 2)
                                .offset(x: 3)
                        )
                    Text("Avg Income")
                        .font(.caption.weight(.medium))
                        .foregroundColor(showAvgIncomeSeries ? .primary : .secondary)
                        .strikethrough(!showAvgIncomeSeries)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            // Tax series toggle
            Button {
                withAnimation(.snappy) {
                    showTaxSeries.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(showTaxSeries ? Color.red : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("Tax")
                        .font(.caption.weight(.medium))
                        .foregroundColor(showTaxSeries ? .primary : .secondary)
                        .strikethrough(!showTaxSeries)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            // Avg Tax series toggle
            Button {
                withAnimation(.snappy) {
                    showAvgTaxSeries.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(showAvgTaxSeries ? Color.purple : Color.secondary.opacity(0.3))
                        .frame(width: 12, height: 2)
                        .overlay(
                            Rectangle()
                                .fill(
                                    showAvgTaxSeries ? Color.purple : Color.secondary.opacity(0.3)
                                )
                                .frame(width: 1, height: 2)
                                .offset(x: -4)
                        )
                        .overlay(
                            Rectangle()
                                .fill(
                                    showAvgTaxSeries ? Color.purple : Color.secondary.opacity(0.3)
                                )
                                .frame(width: 1, height: 2)
                                .offset(x: -1)
                        )
                        .overlay(
                            Rectangle()
                                .fill(
                                    showAvgTaxSeries ? Color.purple : Color.secondary.opacity(0.3)
                                )
                                .frame(width: 1, height: 2)
                                .offset(x: 2)
                        )
                    VStack(spacing: 0) {
                        Text("Avg Tax")
                            .font(.caption.weight(.medium))
                            .foregroundColor(showAvgTaxSeries ? .primary : .secondary)
                            .strikethrough(!showAvgTaxSeries)
                            .lineLimit(1)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    // MARK: - Header (title + big value + green deltas)
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Removed decorative left icon, notification bell, and avatar for a cleaner header per request

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Value")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Real-time tracking")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.airbnbPrimary)
            }

            // Main number
            Text(headlineValue, format: .currency(code: currency))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            // Deltas in green (hide when invested equals value across the period)
            if showInvestedSeries {
                WideStatPill(
                    icon: deltaAmount >= 0 ? "arrow.up.right" : "arrow.down.right",
                    value: abs(deltaAmount),
                    currency: currency,
                    percent: String(format: "%.1f%%", abs(deltaPercent)),
                    tint: deltaAmount >= 0 ? .airbnbSuccess : .red
                )
            }
        }
    }

    // MARK: - Range Selector (exact pill segmented control)
    private var rangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(Range.allCases) { range in
                Button {
                    handleRangeTap(range)
                } label: {
                    rangePill(range)
                }
                .buttonStyle(.plain)
                .disabled(isLoading || selectedEntity == nil)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    colorScheme == .dark ? Color.white.opacity(0.06) : Color.secondary.opacity(0.12)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)),
                    lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, x: 2, y: 6)
    }

    private func handleRangeTap(_ range: Range) {
        if selectedRange != range { startLoading(to: range) }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    @ViewBuilder
    private func rangePill(_ range: Range) -> some View {
        ZStack {
            if selectedEntity != nil && selectedRange == range {
                Capsule(style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .matchedGeometryEffect(id: "selectedPill", in: rangeNS)
            }
            Text(range.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(
                    (selectedEntity != nil && selectedRange == range)
                        ? .black
                        : (colorScheme == .dark
                            ? Color.white.opacity(0.8) : Color.black.opacity(0.6)))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
    }

    // MARK: - Income Filters Bar
    private var incomeFiltersBar: some View {
        VStack(spacing: 8) {
            let activeCount =
                selectedTypes.count + selectedTags.count + selectedYears.count + selectedFYs.count
            HStack(spacing: 8) {

                // Filters button
                Button {
                    showIncomeFilterSheet = true
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

                // Clear button
                if activeCount > 0 {
                    Button {
                        withAnimation(.snappy) {
                            selectedTypes.removeAll()
                            selectedTags.removeAll()
                            selectedYears.removeAll()
                            selectedFYs.removeAll()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill").font(.subheadline)
                            Text("Clear").font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.airbnbPrimary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Color.airbnbPrimary.opacity(0.12)))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }

            // Show applied filters like in Income view
            if activeCount > 0 {
                let sourcesText = selectedTypes.sorted().joined(separator: ", ")
                let tagsText = selectedTags.sorted().joined(separator: ", ")
                let fysText = selectedFYs.sorted { $0.startYear > $1.startYear }
                    .map { $0.title }.joined(separator: ", ")
                let yearsText = selectedYears.sorted(by: >).map(String.init)
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
        }
        .onChange(of: selectedTypes) { reloadIncomeChart() }
        .onChange(of: selectedTags) { reloadIncomeChart() }
        .onChange(of: selectedYears) { reloadIncomeChart() }
        .onChange(of: selectedFYs) { reloadIncomeChart() }
    }

    private func reloadIncomeChart() {
        guard isIncomeChart else { return }
        startLoading(to: selectedRange)
    }

    // MARK: - Entity Selector + Chart
    private var entitySelectorBar: some View {
        HStack(spacing: 8) {
            // Select Source button (shows current selection)
            Button {
                showEntityPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.down.circle.fill").foregroundColor(.airbnbPrimary)
                    Text(selectedEntityName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Capsule().fill(Color.airbnbPrimary.opacity(0.12)))
            }
            .buttonStyle(PressableButtonStyle())

            // Push Filter/Clear to the far right
            Spacer(minLength: 0)

            if isIncomeChart {
                // Filters button
                Button {
                    showIncomeFilterSheet = true
                } label: {
                    let activeCount =
                        selectedTypes.count + selectedTags.count + selectedYears.count
                        + selectedFYs.count
                    HStack(spacing: 8) {
                        Image(
                            systemName: activeCount == 0
                                ? "line.3.horizontal.decrease.circle"
                                : "line.3.horizontal.decrease.circle.fill")
                        Text("Filter")
                            .lineLimit(1)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.airbnbPrimary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Capsule().fill(Color.airbnbPrimary.opacity(0.12)))
                }
                .buttonStyle(PressableButtonStyle())

                // Clear button
                let activeCount =
                    selectedTypes.count + selectedTags.count + selectedYears.count
                    + selectedFYs.count
                if activeCount > 0 {
                    Button {
                        withAnimation(.snappy) {
                            selectedTypes.removeAll()
                            selectedTags.removeAll()
                            selectedYears.removeAll()
                            selectedFYs.removeAll()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill").font(.subheadline)
                            Text("Clear").font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundColor(.airbnbPrimary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Color.airbnbPrimary.opacity(0.12)))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
        .sheet(isPresented: $showEntityPicker) {
            EntityPickerView(userId: userId) { sel in
                selectedEntityName = sel.name
                entityType = sel.type
                entityId = sel.id
                otherChartType = sel.otherType
                startLoading(to: selectedRange)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(data) { point in
                // Current value line (brand accent) - Income series
                if !isIncomeChart || showIncomeSeries {
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Current Value", point.value),
                        series: .value("Current Value", "Current Value")
                    )
                    .lineStyle(
                        StrokeStyle(lineWidth: valueLineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .foregroundStyle(Color.airbnbPrimary)
                    .interpolationMethod(.monotone)
                }

                // Invested line (ink, subtle dashed)
                if showInvestedSeries {
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Invested", point.invested),
                        series: .value("Invested", "Invested")
                    )
                    .lineStyle(
                        StrokeStyle(lineWidth: valueLineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .foregroundStyle(
                        colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.6)
                    )
                    .interpolationMethod(.monotone)
                }

                // Tax paid line (for Income charts only)
                if isIncomeChart && showTaxSeries {
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Tax Paid", point.taxPaid),
                        series: .value("Tax Paid", "Tax Paid")
                    )
                    .lineStyle(
                        StrokeStyle(lineWidth: valueLineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .foregroundStyle(Color.red)
                    .interpolationMethod(.monotone)
                }

                // Average per month line (for Income charts only)
                if isIncomeChart && showAvgIncomeSeries, let avgPerMonth = point.averagePerMonth {
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Average per Month", avgPerMonth),
                        series: .value("Average per Month", "Average per Month")
                    )
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [5, 3])
                    )
                    .foregroundStyle(Color.orange)
                    .interpolationMethod(.monotone)
                }

                // Average tax per month line (for Income charts only)
                if isIncomeChart && showAvgTaxSeries, let avgTaxPerMonth = point.averageTaxPerMonth
                {
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Average Tax per Month", avgTaxPerMonth),
                        series: .value("Average Tax per Month", "Average Tax per Month")
                    )
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [3, 2])
                    )
                    .foregroundStyle(Color.purple)
                    .interpolationMethod(.monotone)
                }
            }

            if let sel = selectedPoint {
                // Vertical rule
                RuleMark(x: .value("Date", sel.date))
                    .foregroundStyle(
                        (colorScheme == .dark
                            ? Color.white.opacity(0.3) : Color.black.opacity(0.25))
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1))

                // Point markers - only show if series is enabled
                if !isIncomeChart || showIncomeSeries {
                    PointMark(x: .value("Date", sel.date), y: .value("Value", sel.value))
                        .foregroundStyle(Color.airbnbPrimary)
                        .symbolSize(36)
                }

                if showInvestedSeries {
                    PointMark(x: .value("Date", sel.date), y: .value("Invested", sel.invested))
                        .foregroundStyle(
                            colorScheme == .dark
                                ? Color.white.opacity(0.85) : Color.black.opacity(0.6)
                        )
                        .symbolSize(36)
                }

                // Tax point marker (for Income charts only)
                if isIncomeChart && showTaxSeries {
                    PointMark(x: .value("Date", sel.date), y: .value("Tax Paid", sel.taxPaid))
                        .foregroundStyle(Color.red)
                        .symbolSize(36)
                }

                // Average income point marker (for Income charts only)
                if isIncomeChart && showAvgIncomeSeries, let avgPerMonth = sel.averagePerMonth {
                    PointMark(
                        x: .value("Date", sel.date), y: .value("Average per Month", avgPerMonth)
                    )
                    .foregroundStyle(Color.orange)
                    .symbolSize(36)
                }

                // Average tax point marker (for Income charts only)
                if isIncomeChart && showAvgTaxSeries, let avgTaxPerMonth = sel.averageTaxPerMonth {
                    PointMark(
                        x: .value("Date", sel.date),
                        y: .value("Average Tax per Month", avgTaxPerMonth)
                    )
                    .foregroundStyle(Color.purple)
                    .symbolSize(36)
                }
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .chartPlotStyle { plot in
            plot
                .padding(.horizontal, 0)  // edge-to-edge horizontally
                .padding(.top, 12)  // prevent circle clipping at max values
        }
        .chartXAxis {
            AxisMarks(values: xAxisTickDatesLimited) { value in
                AxisGridLine().foregroundStyle(.clear)
                AxisTick().foregroundStyle(.clear)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(xAxisLabel(for: date))
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.7) : Color.black.opacity(0.5))
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .overlay(alignment: .center) {
            if isLoading {
                loadingOverlay
            } else if selectedEntity == nil {
                // Empty state prompt to choose a source
                VStack(spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("Choose source to load chart")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    Button("Select Source") { showEntityPicker = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.airbnbPrimary)
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                // Drag/tap to move selection
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .allowsHitTesting(selectedEntity != nil && !isLoading)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { g in handleHover(at: g.location, proxy: proxy, geo: geo) }
                            .onEnded { _ in /* keep selection */ }
                    )
                    .onTapGesture { location in handleHover(at: location, proxy: proxy, geo: geo) }
                    .overlay(
                        Group {
                            if let p = selectedPoint,
                                let x = proxy.position(forX: p.date),
                                let y = proxy.position(forY: p.value)
                            {
                                let plot: CGRect = {
                                    if #available(iOS 17.0, *) {
                                        return geo[proxy.plotFrame!]
                                    } else {
                                        return geo[proxy.plotFrame!]
                                    }
                                }()
                                let absPoint = CGPoint(x: plot.minX + x, y: plot.minY + y)
                                // Use measured tooltip size; provide sensible fallbacks + safety buffer
                                let tWidth: CGFloat = max(tooltipSize.width, 120) + 12
                                let tHeight: CGFloat = max(tooltipSize.height, 44)
                                let edgeInset: CGFloat = 20
                                let gap: CGFloat = 8
                                // Clamp X so bubble stays fully visible without altering domain
                                let clampedX = min(
                                    max(absPoint.x, tWidth / 2 + edgeInset),
                                    geo.size.width - tWidth / 2 - edgeInset)
                                // Prefer placing above the point; if not enough space, place below
                                let topBound = plot.minY + gap + tHeight / 2
                                let bottomBound = plot.maxY - gap - tHeight / 2
                                let aboveY = absPoint.y - gap - tHeight / 2
                                let belowY = absPoint.y + gap + tHeight / 2
                                let chosenY: CGFloat =
                                    aboveY >= topBound
                                    ? aboveY
                                    : (belowY <= bottomBound
                                        ? belowY : min(max(absPoint.y, topBound), bottomBound))
                                VStack(spacing: 6) {
                                    tooltip(for: p)
                                }
                                .position(x: clampedX, y: chosenY)
                                .allowsHitTesting(false)
                            }
                        }
                    )
            }
        }
    }

    // MARK: - Tooltip
    private func tooltip(for p: Point) -> some View {
        // Precompute rows outside ViewBuilder to avoid non-View expressions in the builder
        let rows: [(color: Color, label: String, value: String)] = {
            guard isIncomeChart else { return [] }
            var tmp: [(Color, String, String)] = []
            if showIncomeSeries {
                tmp.append(
                    (.airbnbPrimary, "Income:", p.value.formatted(.currency(code: currency))))
            }
            if showAvgIncomeSeries, let avgPerMonth = p.averagePerMonth {
                tmp.append(
                    (.orange, "Avg Income:", avgPerMonth.formatted(.currency(code: currency))))
            }
            if showTaxSeries {
                tmp.append((.red, "Tax:", p.taxPaid.formatted(.currency(code: currency))))
            }
            if showAvgTaxSeries, let avgTaxPerMonth = p.averageTaxPerMonth {
                tmp.append(
                    (.purple, "Avg Tax:", avgTaxPerMonth.formatted(.currency(code: currency))))
            }
            return tmp
        }()

        return VStack(alignment: .leading, spacing: 4) {
            if isIncomeChart {
                HStack(alignment: .top, spacing: 12) {
                    // Left column: dot + label
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 6) {
                                Circle().fill(item.color).frame(width: 8, height: 8)
                                Text(item.label)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                    }
                    // Right column: value (right-aligned)
                    VStack(alignment: .trailing, spacing: 6) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { _, item in
                            Text(item.value)
                                .font(
                                    .system(
                                        size: 13,
                                        weight: item.label == "Income:" ? .semibold : .semibold)
                                )
                                .foregroundColor(
                                    item.color == .airbnbPrimary
                                        ? (colorScheme == .dark ? .white : .black) : item.color
                                )
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            } else {
                // Non-income chart tooltip

                // Current value
                HStack(spacing: 6) {
                    Circle().fill(Color.airbnbPrimary).frame(width: 8, height: 8)
                    Text(p.value, format: .currency(code: currency))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }

                // Invested value
                if showInvestedSeries {
                    HStack(spacing: 6) {
                        Circle().fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.85) : Color.black.opacity(0.6)
                        ).frame(width: 8, height: 8)
                        Text(p.invested, format: .currency(code: currency))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.85) : Color.black.opacity(0.6))
                    }
                }
            }
            // Profit/Loss percentage vs invested (only when invested differs from value across the period)
            if showInvestedSeries {
                let base = p.invested
                let change = p.value - base
                let pct: Double = (abs(base) > 0.0001) ? (change / abs(base)) * 100.0 : 0
                HStack(spacing: 8) {
                    Image(systemName: pct >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(abs(pct), specifier: "%.1f")%")
                        .font(.system(size: 13, weight: .semibold))
                    Text("•")
                        .font(.system(size: 12, weight: .bold))
                    Text(
                        (change >= 0 ? "+" : "−")
                            + CurrencyShort.shortString(abs(change), currency: currency)
                    )
                    .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(pct >= 0 ? .airbnbSuccess : .red)
            }
            Text(dateFormatter.string(from: p.date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(
                    colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.6)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        // Let tooltip naturally size to its widest child (prevents date from clipping)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.black.opacity(0.9) : Color.white)
                .shadow(
                    color: colorScheme == .dark
                        ? Color.black.opacity(0.4) : Color.black.opacity(0.12), radius: 10, x: 0,
                    y: 6)
        )
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { tooltipSize = proxy.size }
                    .onChange(of: proxy.size) { _, newSize in tooltipSize = newSize }
            }
        )
    }

    // MARK: - Helpers
    private func handleHover(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy) {
        // Convert location to chart X date
        let frame = geo.frame(in: .local)
        let xPos = location.x - frame.origin.x
        if let date: Date = proxy.value(atX: xPos) {
            if let nearest = data.min(by: {
                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
            }) {
                withAnimation(.easeInOut(duration: 0.15)) { selectedPoint = nearest }
            }
        }
    }

    private var xAxisComponent: Calendar.Component {
        switch selectedRange {
        case .oneMonth: return .day
        case .threeMonths: return .day
        case .sixMonths: return .day
        case .oneYear: return .month
        case .twoYears: return .month
        case .fiveYears: return .year
        case .all: return .month
        }
    }
    private var xAxisStride: Int {
        switch selectedRange {
        case .oneMonth: return 7  // weekly
        case .threeMonths: return 14  // bi-weekly
        case .sixMonths: return 30  // monthly
        case .oneYear: return 2  // every 2 months
        case .twoYears: return 3  // quarterly
        case .fiveYears: return 1  // yearly
        case .all: return 3  // quarterly
        }
    }
    private func xAxisLabel(for date: Date) -> String {
        switch selectedRange {
        case .oneMonth: return dayFormatter.string(from: date)
        case .threeMonths: return dayFormatter.string(from: date)
        case .sixMonths: return monthFormatter.string(from: date)
        case .oneYear: return monthFormatter.string(from: date)
        case .twoYears: return monthFormatter.string(from: date)
        case .fiveYears: return yearFormatter.string(from: date)
        case .all: return monthFormatter.string(from: date)
        }
    }

    // Explicitly compute up to 5 tick dates across the visible domain
    private var xAxisTickDatesLimited: [Date] {
        // Tuned fractions reduce the perceived leading gap while keeping labels in-bounds
        guard xDomain.upperBound > xDomain.lowerBound else { return [] }
        let start = xDomain.lowerBound
        let end = xDomain.upperBound
        let total = end.timeIntervalSince(start)
        let fractions: [Double] = [0.0, 0.225, 0.45, 0.675, 0.9]
        return fractions.map { frac in Date(timeInterval: total * frac, since: start) }
    }

    // Whether to render the invested series. If every point has identical value and invested
    // (within a small tolerance to avoid floating point noise), we hide the series entirely.
    private var showInvestedSeries: Bool {
        let epsilon: Double = 0.01  // ~1 paisa/cent tolerance
        return data.contains { abs($0.value - $0.invested) > epsilon }
    }

    private func sampleData(for range: Range) -> [Point] {
        let cal = Calendar.current
        let now = Date()
        func makePoint(
            id: Int, date: Date, v: Double, inv: Double, avgPerMonth: Double? = nil,
            tax: Double = 0, avgTaxPerMonth: Double? = nil
        )
            -> Point
        {
            Point(
                id: id, date: date, value: v, invested: inv, averagePerMonth: avgPerMonth,
                taxPaid: tax, averageTaxPerMonth: avgTaxPerMonth)
        }
        switch range {
        case .oneMonth:
            // 30 days, gradual growth; invested grows smoother below value
            return (0..<30).map { i in
                let date = cal.date(byAdding: .day, value: -(29 - i), to: now) ?? now
                let invested = 1_000_000 + Double(i) * 5_500
                let value = invested + 20_000 + sin(Double(i)) * 12_000
                return makePoint(id: i, date: date, v: value, inv: invested)
            }
        case .threeMonths:
            // 90 days, weekly-ish undulations
            return (0..<90).map { i in
                let date = cal.date(byAdding: .day, value: -(89 - i), to: now) ?? now
                let invested = 980_000 + Double(i) * 3_800
                let value = invested + 35_000 + sin(Double(i) / 6.0) * 18_000
                return makePoint(id: i, date: date, v: value, inv: invested)
            }
        case .sixMonths:
            // 6 months monthly cadence
            return (0..<6).map { i in
                let date = cal.date(byAdding: .month, value: -(5 - i), to: now) ?? now
                let invested = 950_000 + Double(i) * 22_000
                let value = invested + 60_000 + cos(Double(i)) * 20_000
                return makePoint(id: i, date: date, v: value, inv: invested)
            }
        case .oneYear:
            return (0..<12).map { i in
                let date = cal.date(byAdding: .month, value: -(11 - i), to: now) ?? now
                let invested = 900_000 + Double(i) * 40_000
                let value = invested + 80_000 + sin(Double(i)) * 25_000
                return makePoint(id: i, date: date, v: value, inv: invested)
            }
        case .twoYears:
            return (0..<24).map { i in
                let date = cal.date(byAdding: .month, value: -(23 - i), to: now) ?? now
                let invested = 850_000 + Double(i) * 28_000
                let value = invested + 120_000 + sin(Double(i) / 2.0) * 35_000
                return makePoint(id: i, date: date, v: value, inv: invested)
            }
        case .fiveYears:
            return (0..<60).map { i in
                let date = cal.date(byAdding: .month, value: -(59 - i), to: now) ?? now
                let invested = 600_000 + Double(i) * 12_000
                let value = invested + 180_000 + cos(Double(i) / 3.0) * 30_000
                return makePoint(id: i, date: date, v: value, inv: invested)
            }
        case .all:
            return (0..<36).map { i in
                let date = cal.date(byAdding: .month, value: -(35 - i), to: now) ?? now
                let invested = 500_000 + Double(i) * 16_000
                let value = invested + 150_000 + sin(Double(i) / 1.5) * 28_000
                return makePoint(id: i, date: date, v: value, inv: invested)
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"  // show only date
        return df
    }
    private var weekdayFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df
    }
    private var dayFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "d"
        return df
    }
    private var monthFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMM"
        return df
    }
    private var yearFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy"
        return df
    }

    // MARK: - X domain from first to last data point (no extra padding)
    private var xDomain: ClosedRange<Date> {
        guard let start = data.first?.date, let end = data.last?.date else {
            let now = Date()
            return now...now
        }
        return start...end
    }

    // MARK: - Y domain with dynamic padding across both series
    private var yDomain: ClosedRange<Double> {
        var allValues: [Double] = []

        // Add value and invested series
        allValues.append(contentsOf: data.map { $0.value })
        allValues.append(contentsOf: data.map { $0.invested })

        // Add visible series values for income charts to ensure they're within bounds
        if isIncomeChart {
            if showAvgIncomeSeries {
                allValues.append(contentsOf: data.compactMap { $0.averagePerMonth })
            }
            if showTaxSeries {
                allValues.append(contentsOf: data.map { $0.taxPaid })
            }
            if showAvgTaxSeries {
                allValues.append(contentsOf: data.compactMap { $0.averageTaxPerMonth })
            }
        }

        guard let minV = allValues.min(), let maxV = allValues.max() else {
            return 0...1
        }

        let span = max(1, maxV - minV)
        let pad = span * 0.08  // 8% breathing room
        return (minV - pad)...(maxV + pad)
    }

    // MARK: - Presentation tuning based on range
    private var showsAreaFill: Bool {
        switch selectedRange {
        case .oneMonth, .threeMonths: return true
        default: return false
        }
    }
    private var valueLineWidth: CGFloat {
        switch selectedRange {
        case .oneMonth, .threeMonths: return 2.5
        case .sixMonths, .oneYear: return 2.0
        default: return 1.6
        }
    }
    private var investedLineWidth: CGFloat {
        max(1.2, valueLineWidth - 0.6)
    }

    // MARK: - Loading
    private var loadingOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill((colorScheme == .dark ? Color.black.opacity(0.5) : Color.white.opacity(0.7)))
                .frame(width: 90, height: 90)
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.airbnbPrimary)
        }
        // ...
    }

    private func startLoading(to range: Range) {
        guard selectedEntity != nil else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            isLoading = true
            selectedPoint = nil
        }
        Task { await loadChart(for: range) }
    }

    private func loadChart(for range: Range) async {
        guard let selectedEntity = selectedEntity else { return }

        // Handle "Other" chart types with local data generation
        if selectedEntity.type == .other, let otherType = otherChartType {
            await generateOtherChartData(type: otherType, range: range)
            return
        }

        do {
            let client = RestClient()
            let period = mapRangeToPeriod(range)
            let cache = SessionCache.shared
            let cacheKey = SessionCache.ChartKey(
                type: selectedEntity.type, id: selectedEntity.id, period: period)
            let raw: [ChartData]
            if let cached = cache.chartData[cacheKey], !cached.isEmpty {
                raw = cached
            } else {
                let fetched = try await client.fetchChartData(
                    entityType: selectedEntity.type, entityId: selectedEntity.id, timePeriod: period
                )
                cache.chartData[cacheKey] = fetched
                raw = fetched
            }
            // Map to points sorted by date
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.timeZone = TimeZone(secondsFromGMT: 0)
            var mapped: [Point] = raw.enumerated().compactMap { index, r in
                guard let d = fmt.date(from: r.date) else { return nil }
                return Point(
                    id: index, date: d, value: r.value, invested: r.invested, averagePerMonth: nil,
                    taxPaid: 0, averageTaxPerMonth: nil)
            }.sorted { $0.date < $1.date }
            mapped = downsampleEvenTime(mapped, maxCount: 100)
            await MainActor.run {
                self.selectedRange = range
                self.data = mapped
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
            // TODO: surface error state if needed
        }
    }

    private func generateOtherChartData(type: OtherChartType, range: Range) async {
        let cal = Calendar.current
        let now = Date()
        let startDate: Date

        switch range {
        case .oneMonth: startDate = cal.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths: startDate = cal.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths: startDate = cal.date(byAdding: .month, value: -6, to: now) ?? now
        case .oneYear: startDate = cal.date(byAdding: .year, value: -1, to: now) ?? now
        case .twoYears: startDate = cal.date(byAdding: .year, value: -2, to: now) ?? now
        case .fiveYears: startDate = cal.date(byAdding: .year, value: -5, to: now) ?? now
        case .all: startDate = cal.date(byAdding: .year, value: -10, to: now) ?? now
        }

        switch type {
        case .income:
            let points = generateIncomeChartData(from: startDate, to: now)
            await MainActor.run {
                self.selectedRange = range
                self.data = points
                self.isLoading = false
            }
        case .savingsRate:
            // For savings rate, we need to fetch net worth data asynchronously
            await fetchNetWorthDataForSavedPercentage(from: startDate, to: now, range: range)
        }
    }

    private func generateIncomeChartData(from startDate: Date, to endDate: Date) -> [Point] {
        // Use filtered incomes based on current filter selections
        let allIncomes = filteredIncomes.sorted { $0.creditedDate < $1.creditedDate }

        // Calculate cumulative income up to start date (for proper baseline)
        let baselineIncome = allIncomes.filter { $0.creditedDate < startDate }
            .reduce(0.0) { $0 + $1.netAmount }

        // Get incomes within the selected range
        let rangeIncomes = allIncomes.filter { income in
            income.creditedDate >= startDate && income.creditedDate <= endDate
        }

        // When filters are applied, use the first record from filtered records for avg calculation
        let hasFilters =
            !selectedTypes.isEmpty || !selectedTags.isEmpty || !selectedYears.isEmpty
            || !selectedFYs.isEmpty
        let firstIncomeDate: Date

        if hasFilters,
            let firstFilteredDate = filteredIncomes.sorted(by: { $0.creditedDate < $1.creditedDate }
            ).first?.creditedDate
        {
            firstIncomeDate = firstFilteredDate
        } else {
            // Use the very first income date across all incomes (not just filtered)
            let allIncomesForBaseline = lookup.incomes.sorted { $0.creditedDate < $1.creditedDate }
            guard let firstDate = allIncomesForBaseline.first?.creditedDate else {
                return []
            }
            firstIncomeDate = firstDate
        }

        var cumulativeIncome = baselineIncome
        var cumulativeTax = allIncomes.filter { $0.creditedDate < startDate }
            .reduce(0.0) { $0 + $1.taxPaid }

        // Get the 1st of the month of the first income for average calculation
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: firstIncomeDate)
        let firstOfMonth = calendar.date(from: components) ?? firstIncomeDate

        return rangeIncomes.enumerated().map { index, income in
            cumulativeIncome += income.netAmount
            cumulativeTax += income.taxPaid

            // Calculate average per calendar month
            // Formula: total cumulative net income until that chart day / sum of total days from the 1st of the month of first income to until that chart day * 1 calendar day (30.44 days average)
            let totalDaysFromFirst =
                calendar.dateComponents(
                    [.day], from: firstOfMonth, to: income.creditedDate
                ).day ?? 0
            let averagePerDay =
                totalDaysFromFirst > 0 ? cumulativeIncome / Double(totalDaysFromFirst) : 0
            let averagePerMonth = averagePerDay * 30.44  // Average days per month

            // Calculate average tax per calendar month
            let averageTaxPerDay =
                totalDaysFromFirst > 0 ? cumulativeTax / Double(totalDaysFromFirst) : 0
            let averageTaxPerMonth = averageTaxPerDay * 30.44  // Average days per month

            return Point(
                id: index,
                date: income.creditedDate,
                value: cumulativeIncome,
                invested: cumulativeIncome,  // For income, invested = value (no separate investment concept)
                averagePerMonth: averagePerMonth,
                taxPaid: cumulativeTax,
                averageTaxPerMonth: averageTaxPerMonth
            )
        }
    }

    private func generateSavedPercentageData(from startDate: Date, to endDate: Date, range: Range)
        -> [Point]
    {
        // First, fetch net worth data from "All Watchlists" chart data
        Task {
            await fetchNetWorthDataForSavedPercentage(from: startDate, to: endDate, range: range)
        }

        // Return empty for now - will be populated by async fetch
        return []
    }

    private func fetchNetWorthDataForSavedPercentage(
        from startDate: Date, to endDate: Date, range: Range
    ) async {
        do {
            let client = RestClient()
            let period = mapRangeToPeriod(range)

            // Find "All" watchlist ID from lookup store
            guard
                let allWatchlist = lookup.watchlists.first(where: {
                    $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        .localizedCaseInsensitiveCompare("All") == .orderedSame
                })
            else {
                await MainActor.run { self.isLoading = false }
                return
            }

            // Fetch chart data for "All Watchlists" to get net worth progression
            let netWorthData = try await client.fetchChartData(
                entityType: .watchlist,
                entityId: allWatchlist.id,
                timePeriod: period
            )

            // Convert to date-indexed dictionary for lookup
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.timeZone = TimeZone(secondsFromGMT: 0)

            var netWorthByDate: [Date: Double] = [:]
            for data in netWorthData {
                if let date = fmt.date(from: data.date) {
                    netWorthByDate[date] = data.value
                }
            }

            // Generate savings percentage points for all available net worth dates
            var points: [Point] = []
            let sortedNetWorthDates = netWorthByDate.keys.sorted()

            for (index, date) in sortedNetWorthDates.enumerated() {
                // Only include dates within our selected range
                guard date >= startDate && date <= endDate else { continue }

                // Get net worth for this date
                let netWorth = netWorthByDate[date] ?? 0

                // Calculate cumulative net income up to this date
                let cumulativeNetIncome = lookup.incomes.filter { $0.creditedDate <= date }
                    .reduce(0.0) { $0 + $1.netAmount }

                // Calculate savings percentage: Net worth / Cumulative net income * 100
                let savedPercentage =
                    cumulativeNetIncome > 0 ? (netWorth / cumulativeNetIncome) * 100 : 0

                points.append(
                    Point(
                        id: index,
                        date: date,
                        value: savedPercentage,
                        invested: savedPercentage,
                        averagePerMonth: nil,
                        taxPaid: 0,
                        averageTaxPerMonth: nil
                    ))
            }

            // Apply downsampling to max 100 points (same as other chart types)
            let downsampledPoints = downsampleEvenTime(points, maxCount: 100)

            await MainActor.run {
                self.selectedRange = range
                self.data = downsampledPoints
                self.isLoading = false
            }

        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }

    private func getNetWorthForDate(
        _ targetDate: Date, from netWorthByDate: [Date: Double], netWorthData: [ChartData]
    ) -> Double {
        // Try exact match first
        if let exactValue = netWorthByDate[targetDate] {
            return exactValue
        }

        // Find closest dates for interpolation
        let sortedDates = netWorthByDate.keys.sorted()

        // Find the closest date before or equal to target
        var beforeDate: Date?
        var afterDate: Date?

        for date in sortedDates {
            if date <= targetDate {
                beforeDate = date
            } else if afterDate == nil {
                afterDate = date
                break
            }
        }

        // Use the closest available value
        if let before = beforeDate, let beforeValue = netWorthByDate[before] {
            if let after = afterDate, let afterValue = netWorthByDate[after] {
                // Interpolate between before and after
                let totalInterval = after.timeIntervalSince(before)
                let targetInterval = targetDate.timeIntervalSince(before)
                let ratio = totalInterval > 0 ? targetInterval / totalInterval : 0
                return beforeValue + (afterValue - beforeValue) * ratio
            } else {
                // Use before value
                return beforeValue
            }
        } else if let after = afterDate, let afterValue = netWorthByDate[after] {
            // Use after value
            return afterValue
        }

        // Fallback to current account values if no chart data available
        return lookup.accounts.reduce(0.0) { $0 + $1.currentDayValue }
    }

    // Downsample to maxCount using evenly spaced time targets between first and last date.
    // For each target time, pick the nearest point; always includes first and last.
    private func downsampleEvenTime(_ points: [Point], maxCount: Int) -> [Point] {
        guard points.count > maxCount, maxCount >= 2,
            let first = points.first, let last = points.last
        else { return points }
        let k = maxCount
        let total = last.date.timeIntervalSince(first.date)
        guard total > 0 else { return Array(points.prefix(k)) }
        var result: [Point] = []
        result.reserveCapacity(k)
        var idx = 0
        for i in 0..<(k - 1) {
            let targetTime = first.date.addingTimeInterval((Double(i) * total) / Double(k - 1))
            // advance idx to the first point with date >= targetTime
            while idx + 1 < points.count && points[idx + 1].date < targetTime { idx += 1 }
            // choose closer between idx and idx+1
            let current = points[idx]
            if idx + 1 < points.count {
                let next = points[idx + 1]
                let d1 = abs(current.date.timeIntervalSince(targetTime))
                let d2 = abs(next.date.timeIntervalSince(targetTime))
                result.append(d2 < d1 ? next : current)
            } else {
                result.append(current)
            }
        }
        result.append(last)
        // Remove duplicates by date to avoid clutter
        var seen = Set<Date>()
        let unique = result.filter { p in
            if seen.contains(p.date) { return false }
            seen.insert(p.date)
            return true
        }
        return unique
    }

    private func mapRangeToPeriod(_ range: Range) -> ChartTimePeriod {
        switch range {
        case .oneMonth: return .oneMonth
        case .threeMonths: return .threeMonths
        case .sixMonths: return .sixMonths
        case .oneYear: return .oneYear
        case .twoYears: return .twoYears
        case .fiveYears: return .fiveYears
        case .all: return .all
        }
    }
}
