import SwiftUI
import Charts

// MARK: - Asset Overview Card (matches the attached design)
struct AssetOverviewCard: View {
    // MARK: - Types
    enum Range: String, CaseIterable, Identifiable {
        case oneWeek = "1w"
        case oneMonth = "1m"
        case oneYear = "1y"
        case fiveYears = "5y"
        case all = "All"
        
        var id: String { rawValue }
        var title: String { rawValue }
    }
    
    struct Point: Identifiable, Hashable {
        let id: Int
        let date: Date
        let value: Double
    }
    
    // MARK: - State
    @State private var selectedRange: Range = .oneWeek
    @State private var selectedPoint: Point?
    @AppStorage("defaultCurrencyCode") private var currency: String = "INR"
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var rangeNS
    @State private var tooltipSize: CGSize = .zero
    @State private var isLoading: Bool = false
    
    // Generated demo data to match the look-and-feel of the design
    private var data: [Point] { sampleData(for: selectedRange) }
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
            rangeSelector
            chart
                .frame(height: 220)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
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
                    .disabled(isLoading)
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
    
    // MARK: - Chart
    private var chart: some View {
        Chart {
            ForEach(data) { point in
                // Area fill (very light gradient bottom up)
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: colorScheme == .dark ? [Color.airbnbPrimary.opacity(0.18), Color.clear] : [Color.airbnbPrimary.opacity(0.20), Color.airbnbPrimary.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.linear)
                
                // Main stroke line (sharp angles like image)
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.airbnbPrimary)
                .interpolationMethod(.linear)
            }

            if let sel = selectedPoint {
                // Vertical rule
                RuleMark(x: .value("Date", sel.date))
                    .foregroundStyle((colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.25)))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                
                // Selection point (white base circle)
                PointMark(
                    x: .value("Date", sel.date),
                    y: .value("Value", sel.value)
                )
                .symbol(Circle())
                .foregroundStyle(Color.white)
                .symbolSize(130)

                // Selection point (accent inner circle to create ring effect)
                PointMark(
                    x: .value("Date", sel.date),
                    y: .value("Value", sel.value)
                )
                .symbol(Circle())
                .foregroundStyle(Color.airbnbPrimary)
                .symbolSize(80)
            }
        }
        .chartXScale(domain: xDomain)
        .chartPlotStyle { plot in
            plot
                .padding(.horizontal, 0) // edge-to-edge horizontally
                .padding(.top, 20) // prevent circle clipping at max values
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
            Text(p.value, format: .currency(code: currency))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
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
        case .oneWeek: return .day
        case .oneMonth: return .day
        case .oneYear: return .month
        case .fiveYears: return .year
        case .all: return .month
        }
    }
    private var xAxisStride: Int {
        switch selectedRange {
        case .oneWeek: return 1              // every day
        case .oneMonth: return 7             // every 7th day (~weekly)
        case .oneYear: return 2              // every 2 months
        case .fiveYears: return 1            // every year
        case .all: return 3                  // every 3 months (quarterly)
        }
    }
    private func xAxisLabel(for date: Date) -> String {
        switch selectedRange {
        case .oneWeek: return dayFormatter.string(from: date) // show only date (no weekday)
        case .oneMonth: return dayFormatter.string(from: date)
        case .oneYear: return monthFormatter.string(from: date)
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
        switch range {
        case .oneWeek:
            // 7 points Mon-Sun with a clear upward trend and small dips
            return (0..<7).map { i in
                let date = cal.date(byAdding: .day, value: -(6 - i), to: now) ?? now
                let base: Double = 1_100_000
                let steps: [Double] = [0, 30_000, 15_000, 5_000, 45_000, 25_000, 60_000]
                return Point(id: i, date: date, value: base + steps[i])
            }
        case .oneMonth:
            return (0..<30).map { i in
                let date = cal.date(byAdding: .day, value: -(29 - i), to: now) ?? now
                let base: Double = 1_050_000
                let v = base + Double(i) * 8_000 + sin(Double(i)) * 12_000
                return Point(id: i, date: date, value: v)
            }
        case .oneYear:
            return (0..<12).map { i in
                let date = cal.date(byAdding: .month, value: -(11 - i), to: now) ?? now
                let base: Double = 950_000
                let v = base + Double(i) * 40_000 + sin(Double(i)) * 25_000
                return Point(id: i, date: date, value: v)
            }
        case .fiveYears:
            return (0..<60).map { i in
                let date = cal.date(byAdding: .month, value: -(59 - i), to: now) ?? now
                let base: Double = 600_000
                let v = base + Double(i) * 12_000 + cos(Double(i)) * 18_000
                return Point(id: i, date: date, value: v)
            }
        case .all:
            return (0..<36).map { i in
                let date = cal.date(byAdding: .month, value: -(35 - i), to: now) ?? now
                let base: Double = 500_000
                let v = base + Double(i) * 16_000 + sin(Double(i)) * 14_000
                return Point(id: i, date: date, value: v)
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
        .allowsHitTesting(true)
    }

    private func startLoading(to range: Range) {
        withAnimation(.easeInOut(duration: 0.15)) { isLoading = true; selectedPoint = nil }
        // Simulate async load. Replace with your real fetch.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedRange = range
                isLoading = false
            }
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
