import SwiftUI

// MARK: - Income
struct IncomeListView: View {
    @StateObject private var vm: IncomeController
    @State private var navCollapsed = false
    
    init(userId: Int) {
        _vm = StateObject(wrappedValue: IncomeController(userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.canvasBackground.ignoresSafeArea()
                ScrollView {
                    GeometryReader { proxy in
                        Color.clear.preference(key: NavBarOffsetKey.self, value: proxy.frame(in: .named("incomeScroll")).minY)
                    }
                    .frame(height: 0)
                    VStack(spacing: 16) {
                        SummaryCard(totalAll: vm.totalAll, currency: vm.displayCurrency, trend: vm.monthlySumsLast12)
                            .padding(.top, 8)
                        
                        FilterBar(selectedType: $vm.selectedType, types: vm.uniqueTypes)
                        
                        if let message = vm.errorMessage {
                            ErrorCard(message: message) { Task { await vm.refresh() } }
                        }
                        
                        if vm.isLoading && vm.incomes.isEmpty {
                            ForEach(0..<5, id: \.self) { _ in
                                IncomeRowCard.placeholder()
                            }
                            .shimmer()
                        } else if vm.sections.isEmpty {
                            EmptyStateCard(text: "No income records yet")
                        } else {
                            LazyVStack(spacing: 12, pinnedViews: []) {
                                ForEach(vm.sections) { section in
                                    SectionHeader(title: section.title)
                                        .padding(.top, 8)
                                    ForEach(section.items, id: \.id) { item in
                                        IncomeRowCard(income: item)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: "incomeScroll")
            }
            .overlay(alignment: .bottomTrailing) {
                FloatingAddButton { Haptics.softImpact() }
                    .padding(.trailing, 16)
                    .padding(.bottom, 96)
            }
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
        .animation(.easeInOut(duration: 0.2), value: vm.selectedType)
    }
}

private struct SummaryCard: View {
    let totalAll: Double
    let currency: String
    let trend: [Double]
    
    var body: some View {
        let last = trend.last ?? 0
        let prev = trend.dropLast().last ?? 0
        let delta = last - prev
        let pct = prev != 0 ? delta / prev : 0
        return VStack(alignment: .leading, spacing: 12) {
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
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
        .overlay(alignment: .topTrailing) {
            Sparkline(values: trend)
                .frame(width: 140, height: 64)
                .padding(10)
                .opacity(0.75)
        }
        .overlay(alignment: .topTrailing) {
            TrendBadge(delta: delta, pct: pct, currency: currency)
                .padding(.trailing, 10)
                .padding(.top, 52)
        }
        .tilt(amount: 0.35)
        .accessibilityElement(children: .combine)
    }
}

private struct TrendBadge: View {
    let delta: Double
    let pct: Double
    let currency: String
    
    var body: some View {
        let isUp = delta > 0.0001
        let color = isUp ? Color.airbnbSuccess : (delta < -0.0001 ? Color.airbnbPrimary : Color.secondary)
        HStack(spacing: 6) {
            Image(systemName: isUp ? "arrow.up.right" : (delta < -0.0001 ? "arrow.down.right" : "equal"))
                .font(.caption.bold())
            Text(pct, format: .percent.precision(.fractionLength(0...1)))
                .font(.footnote).bold()
            Text("(\(delta, format: .currency(code: currency)))")
                .font(.caption2)
                .opacity(0.8)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .foregroundColor(.white)
        .background(
            Capsule(style: .continuous)
                .fill(color.gradient)
        )
        .accessibilityLabel(isUp ? "Up by \(Int(pct * 100)) percent" : (delta < -0.0001 ? "Down by \(Int(-pct * 100)) percent" : "No change"))
    }
}

private struct StatPill: View {
    let title: String
    let value: Double
    let currency: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value, format: .currency(code: currency))
                .font(.headline)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.45), value: value)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule(style: .continuous)
                .fill(Color.airbnbPrimary.opacity(0.08))
        )
    }
}

private struct FilterBar: View {
    @Binding var selectedType: String?
    let types: [String]
    @Namespace private var ns
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.airbnbPrimary)
                    .symbolEffect(.bounce, value: selectedType)
                
                FilterChip(label: "All", isSelected: selectedType == nil, ns: ns) {
                    withAnimation(.snappy) { selectedType = nil }
                    Haptics.selection()
                }
                
                ForEach(types, id: \.self) { t in
                    FilterChip(label: t, isSelected: selectedType == t, ns: ns) {
                        withAnimation(.snappy) { selectedType = t }
                        Haptics.selection()
                    }
                }
                
                if selectedType != nil {
                    ClearFilterChip {
                        withAnimation(.snappy) { selectedType = nil }
                        Haptics.selection()
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 6)
        }
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let ns: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.clear : Color.subtleSeparator)
                )
                .background(
                    Group {
                        if isSelected {
                            Capsule(style: .continuous)
                                .fill(LinearGradient.airbnbAccent)
                                .matchedGeometryEffect(id: "chipHighlight", in: ns)
                        }
                    }
                )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct ClearFilterChip: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill").font(.subheadline)
                Text("Clear").font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.airbnbPrimary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.airbnbPrimary.opacity(0.12))
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.title3).bold()
            Spacer()
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 4)
    }
}

private struct IncomeRowCard: View {
    let income: Income
    
    var body: some View {
        Button {
            Haptics.softImpact()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Capsule()
                    .fill(Color.airbnbPrimary.opacity(0.2))
                    .frame(width: 6, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(income.incomeTag.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text("\(income.incomeType.name) • \(DateFormatter.dayMonYear.string(from: income.creditedDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(income.amount, format: .currency(code: income.currency))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.elevatedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.subtleSeparator, lineWidth: 1)
            )
            .elevatedShadow()
        }
        .buttonStyle(PressableButtonStyle())
        .transition(.moveAndFade)
        .contextMenu {
            Button("Copy amount") { UIPasteboard.general.string = String(format: "%.2f", income.amount) }
            Button("Copy date") { UIPasteboard.general.string = DateFormatter.dayMonYear.string(from: income.creditedDate) }
            Button("Copy tag") { UIPasteboard.general.string = income.incomeTag.name }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                Haptics.selection()
            } label: { Label("Details", systemImage: "info.circle") }
            .tint(.airbnbPrimary)
        }
    }
}

private extension IncomeRowCard {
    static func placeholder() -> some View {
        HStack(alignment: .center, spacing: 12) {
            Capsule()
                .fill(Color.airbnbPrimary.opacity(0.2))
                .frame(width: 6, height: 44)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.subtleSeparator).frame(width: 120, height: 16)
                RoundedRectangle(cornerRadius: 4).fill(Color.subtleSeparator).frame(width: 180, height: 14)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 4).fill(Color.subtleSeparator).frame(width: 80, height: 18)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
        )
        .elevatedShadow()
    }
}

// MARK: - Sparkline
private struct Sparkline: View {
    let values: [Double]
    @State private var progress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let points = normalized(values: values)
            let path = Path { p in
                guard !points.isEmpty else { return }
                let stepX = points.count > 1 ? size.width / CGFloat(points.count - 1) : 0
                for (idx, v) in points.enumerated() {
                    let x = CGFloat(idx) * stepX
                    let y = size.height - (CGFloat(v) * size.height)
                    if idx == 0 { p.move(to: CGPoint(x: x, y: y)) }
                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            
            path.trim(from: 0, to: progress)
                .stroke(LinearGradient.airbnbAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .shadow(color: .airbnbPrimary.opacity(0.25), radius: 4, x: 0, y: 2)
            
            path.trim(from: 0, to: progress)
                .fill(
                    LinearGradient(
                        colors: [.airbnbPrimary.opacity(0.18), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(
                    VStack(spacing: 0) {
                        path.stroke(style: StrokeStyle(lineWidth: 0)).opacity(0)
                        Rectangle().fill(Color.white)
                    }
                )
        }
        .onAppear { withAnimation(.easeOut(duration: 0.9)) { progress = 1 } }
        .onChange(of: values) { _, _ in
            progress = 0
            withAnimation(.easeOut(duration: 0.9)) { progress = 1 }
        }
    }
    
    private func normalized(values: [Double]) -> [Double] {
        guard let maxV = values.max(), let minV = values.min(), maxV > minV else {
            return values.map { _ in 0.5 }
        }
        let range = maxV - minV
        return values.map { ($0 - minV) / range }
    }
}

// MARK: - Floating Add Button
private struct FloatingAddButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(LinearGradient.airbnbAccent)
                )
                .shadow(color: .airbnbPrimary.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.94))
        .accessibilityLabel("Add income")
    }
}

// MARK: - Cards
private struct ErrorCard: View {
    let message: String
    var retry: () -> Void
    @State private var showDetails: Bool = false
    var body: some View {
        let isNetwork = message.localizedCaseInsensitiveContains("network") || message.localizedCaseInsensitiveContains("internet") || message.localizedCaseInsensitiveContains("offline")
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle().fill(Color.airbnbPrimary.opacity(0.12))
                    Image(systemName: isNetwork ? "wifi.exclamationmark" : "exclamationmark.triangle.fill")
                        .foregroundColor(.airbnbPrimary)
                }
                .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isNetwork ? "No internet connection" : "Something went wrong")
                        .font(.headline)
                    Text(isNetwork ? "You're offline or the connection was lost. Check your internet and try again." : "Please try again in a moment.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Button(action: retry) {
                    Text("Retry").bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Capsule(style: .continuous).fill(LinearGradient.airbnbAccent))
                        .foregroundColor(.white)
                }
                .buttonStyle(PressableButtonStyle())
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showDetails.toggle() } }) {
                    Text(showDetails ? "Hide details" : "Details")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .tint(.secondary)
            }
            if showDetails {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
        )
        .elevatedShadow()
    }
}

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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
        )
        .elevatedShadow()
    }
}
