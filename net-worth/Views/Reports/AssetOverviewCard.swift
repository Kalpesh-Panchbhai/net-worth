import SwiftUI
import Charts

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
    @State private var selectedEntityName: String = "Choose source"
    @State private var showEntityPicker: Bool = false
    @State private var userId: Int = 1 // TODO: Inject from app state / auth
    // Live data
    @State private var data: [Point] = []
    
    // Init allowing caller to specify what to chart
    init() {}
    private var headlineValue: Double { data.last?.value ?? 0 }
    private var deltaPercent: Double {
        guard let first = data.first?.value, let last = data.last?.value, first > 0 else { return 0 }
        return ((last - first) / first) * 100
    }
    private var deltaAmount: Double {
        guard let first = data.first?.value, let last = data.last?.value else { return 0 }
        return last - first
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            header
            entitySelectorBar
            rangeSelector
            chart
                .frame(minHeight: 320)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Header (title + big value + green deltas)
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Removed decorative left icon, notification bell, and avatar for a cleaner header per request
            
            Text("Your Total Asset")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Main number
            Text(headlineValue, format: .currency(code: currency))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            // Deltas in green
            HStack(spacing: 12) {
                Label("\(String(format: "%.1f%%", abs(deltaPercent)))", systemImage: deltaPercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(.airbnbSuccess)
                    .font(.system(size: 14, weight: .semibold))
                
                Text("+" + CurrencyShort.shortString(abs(deltaAmount), currency: currency))
                    .foregroundColor(.airbnbSuccess)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
    }
    
    // MARK: - Range Selector (exact pill segmented control)
    private var rangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(Range.allCases) { range in
                Button { handleRangeTap(range) } label: { rangePill(range) }
                    .buttonStyle(.plain)
                    .disabled(isLoading || selectedEntity == nil)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.secondary.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke((colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)), lineWidth: 1)
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
            if selectedRange == range {
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
                .foregroundColor(selectedRange == range ? .black : (colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.6)))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
    }
    
    // MARK: - Entity Selector + Chart
    private var entitySelectorBar: some View {
        HStack {
            Button {
                showEntityPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.down.circle.fill").foregroundColor(.airbnbPrimary)
                    Text(selectedEntityName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                )
            }
            Spacer()
        }
        .sheet(isPresented: $showEntityPicker) {
            EntityPickerView(userId: userId) { sel in
                selectedEntityName = sel.name
                entityType = sel.type
                entityId = sel.id
                startLoading(to: selectedRange)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(data) { point in
                // Current value line (brand accent)
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Current Value", point.value),
                    series: .value("Current Value", "Current Value")
                )
                .lineStyle(StrokeStyle(lineWidth: valueLineWidth, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.airbnbPrimary)
                .interpolationMethod(.monotone)

                // Invested line (ink, subtle dashed)
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Invested", point.invested),
                    series: .value("Invested", "Invested")
                )
                .lineStyle(StrokeStyle(lineWidth: valueLineWidth, lineCap: .round, lineJoin: .round))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.6))
                .interpolationMethod(.monotone)
            }

            if let sel = selectedPoint {
                // Vertical rule
                RuleMark(x: .value("Date", sel.date))
                    .foregroundStyle((colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.25)))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                
                // Selection point (white base circle)
                PointMark(
                    x: .value("Date", sel.date),
                    y: .value("Current Value", sel.value)
                )
                .symbol(Circle())
                .foregroundStyle(Color.white)
                .symbolSize(130)

                // Selection point (accent inner circle to create ring effect)
                PointMark(
                    x: .value("Date", sel.date),
                    y: .value("Current Value", sel.value)
                )
                .symbol(Circle())
                .foregroundStyle(Color.airbnbPrimary)
                .symbolSize(80)
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .chartPlotStyle { plot in
            plot
                .padding(.horizontal, 0) // edge-to-edge horizontally
                .padding(.top, 12) // prevent circle clipping at max values
        }
        .chartXAxis {
            AxisMarks(values: xAxisTickDatesLimited) { value in
                AxisGridLine().foregroundStyle(.clear)
                AxisTick().foregroundStyle(.clear)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(xAxisLabel(for: date))
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.5))
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
                               let y = proxy.position(forY: p.value) {
                                let plot: CGRect = {
                                    if #available(iOS 17.0, *), let pf = proxy.plotFrame {
                                        return geo[pf]
                                    } else {
                                        return geo[proxy.plotAreaFrame]
                                    }
                                }()
                                let absPoint = CGPoint(x: plot.minX + x, y: plot.minY + y)
                                // Use measured tooltip size; provide sensible fallbacks
                                let tWidth: CGFloat = max(tooltipSize.width, 120)
                                let tHeight: CGFloat = max(tooltipSize.height, 44)
                                let edgeInset: CGFloat = 20
                                let gap: CGFloat = 8
                                // Clamp X so bubble stays fully visible without altering domain
                                let clampedX = min(max(absPoint.x, tWidth/2 + edgeInset), geo.size.width - tWidth/2 - edgeInset)
                                // Prefer placing above the point; if not enough space, place below
                                let topBound = plot.minY + gap + tHeight/2
                                let bottomBound = plot.maxY - gap - tHeight/2
                                let aboveY = absPoint.y - gap - tHeight/2
                                let belowY = absPoint.y + gap + tHeight/2
                                let chosenY: CGFloat =
                                    aboveY >= topBound ? aboveY : (belowY <= bottomBound ? belowY : min(max(absPoint.y, topBound), bottomBound))
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
        VStack(alignment: .leading, spacing: 4) {
            // Current value
            HStack(spacing: 6) {
                Circle().fill(Color.airbnbPrimary).frame(width: 8, height: 8)
                Text(p.value, format: .currency(code: currency))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            // Invested value
            HStack(spacing: 6) {
                Circle().fill(colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.6)).frame(width: 8, height: 8)
                Text(p.invested, format: .currency(code: currency))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.6))
            }
            Text(dateFormatter.string(from: p.date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.black.opacity(0.9) : Color.white)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        )
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { tooltipSize = proxy.size }
            }
        )
    }
    
    // MARK: - Helpers
    private func handleHover(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy) {
        // Convert location to chart X date
        let frame = geo.frame(in: .local)
        let xPos = location.x - frame.origin.x
        if let date: Date = proxy.value(atX: xPos) {
            if let nearest = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
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
        case .oneMonth: return 7             // weekly
        case .threeMonths: return 14         // bi-weekly
        case .sixMonths: return 30           // monthly
        case .oneYear: return 2              // every 2 months
        case .twoYears: return 3             // quarterly
        case .fiveYears: return 1            // yearly
        case .all: return 3                  // quarterly
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
    
    private func sampleData(for range: Range) -> [Point] {
        let cal = Calendar.current
        let now = Date()
        func makePoint(id: Int, date: Date, v: Double, inv: Double) -> Point {
            Point(id: id, date: date, value: v, invested: inv)
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
                let value = invested + 35_000 + sin(Double(i)/6.0) * 18_000
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
                let value = invested + 120_000 + sin(Double(i)/2.0) * 35_000
                return makePoint(id: i, date: date, v: value, inv: invested)
            }
        case .fiveYears:
            return (0..<60).map { i in
                let date = cal.date(byAdding: .month, value: -(59 - i), to: now) ?? now
                let invested = 600_000 + Double(i) * 12_000
                let value = invested + 180_000 + cos(Double(i)/3.0) * 30_000
                return makePoint(id: i, date: date, v: value, inv: invested)
            }
        case .all:
            return (0..<36).map { i in
                let date = cal.date(byAdding: .month, value: -(35 - i), to: now) ?? now
                let invested = 500_000 + Double(i) * 16_000
                let value = invested + 150_000 + sin(Double(i)/1.5) * 28_000
                return makePoint(id: i, date: date, v: value, inv: invested)
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy" // show only date
        return df
    }
    private var weekdayFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df
    }
    private var dayFormatter: DateFormatter { let df = DateFormatter(); df.dateFormat = "d"; return df }
    private var monthFormatter: DateFormatter { let df = DateFormatter(); df.dateFormat = "MMM"; return df }
    private var yearFormatter: DateFormatter { let df = DateFormatter(); df.dateFormat = "yyyy"; return df }
    
    // MARK: - X domain from first to last data point (no extra padding)
    private var xDomain: ClosedRange<Date> {
        guard let start = data.first?.date, let end = data.last?.date else { let now = Date(); return now...now }
        return start...end
    }

    // MARK: - Y domain with dynamic padding across both series
    private var yDomain: ClosedRange<Double> {
        guard let minV = (data.map { min($0.value, $0.invested) }.min()),
              let maxV = (data.map { max($0.value, $0.invested) }.max()) else {
            return 0...1
        }
        let span = max(1, maxV - minV)
        let pad = span * 0.08 // 8% breathing room
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
        withAnimation(.easeInOut(duration: 0.15)) { isLoading = true; selectedPoint = nil }
        Task { await loadChart(for: range) }
    }

    private func loadChart(for range: Range) async {
        guard let selectedEntity = selectedEntity else { return }
        do {
            let client = RestClient()
            let period = mapRangeToPeriod(range)
            let raw = try await client.fetchChartData(entityType: selectedEntity.type, entityId: selectedEntity.id, timePeriod: period)
            // Map to points sorted by date
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"; fmt.timeZone = TimeZone(secondsFromGMT: 0)
            var mapped: [Point] = raw.compactMap { r in
                guard let d = fmt.date(from: r.date) else { return nil }
                return Point(id: r.id, date: d, value: r.value, invested: r.invested)
            }.sorted { $0.date < $1.date }
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

#Preview {
    ScrollView {
        AssetOverviewCard()
            .padding()
            .background(
                LinearGradient(colors: [Color.blue.opacity(0.08), Color.clear], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
    }
}
