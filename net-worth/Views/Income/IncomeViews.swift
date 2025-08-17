import SwiftUI

// MARK: - Income
struct IncomeListView: View {
    @StateObject private var vm: IncomeController
    @State private var navCollapsed = false
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var tabCommands: TabCommandCenter
    @State private var showFilterSheet = false
    
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
                            Color.clear.preference(key: NavBarOffsetKey.self, value: geo.frame(in: .named("incomeScroll")).minY)
                        }
                        .frame(height: 0)
                        VStack(spacing: 16) {
                            SummaryCard(totalAll: vm.totalAll, totalNet: vm.totalNet, totalTax: vm.totalTaxPaid, currency: vm.displayCurrency)
                                .padding(.top, 8)
                            HStack {
                                Button {
                                    showFilterSheet = true
                                    Haptics.selection()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                        Text(vm.selectedType == nil ? "Filter" : vm.selectedType!)
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.airbnbPrimary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Capsule().fill(Color.airbnbPrimary.opacity(0.12)))
                                }
                                .buttonStyle(PressableButtonStyle())
                                Spacer(minLength: 0)
                            }
                            
                            if vm.isLoading && vm.incomes.isEmpty {
                                ForEach(0..<5, id: \.self) { _ in
                                    IncomeRowCard.placeholder()
                                }
                                .shimmer()
                            } else if vm.sections.isEmpty {
                                EmptyStateCard(text: "No income records yet")
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(vm.sections) { section in
                                        SectionHeader(title: section.title)
                                            .padding(.top, 8)
                                        ForEach(section.items, id: \.id) { item in
                                            IncomeRowCard(income: item)
                                        }
                                    }
                                }
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
        .onChange(of: vm.errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            banners.showError(message: message, retryTitle: "Retry", retry: { Task { await vm.refresh() } })
        }
        .sheet(isPresented: $showFilterSheet) {
            NavigationStack {
                FilterSheet(types: vm.uniqueTypes, selected: $vm.selectedType) {
                    showFilterSheet = false
                } onClear: {
                    vm.selectedType = nil
                }
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Close") { showFilterSheet = false } }
                    ToolbarItem(placement: .confirmationAction) { Button("Apply") { showFilterSheet = false } }
                }
                .toolbarBackground(Color.canvasBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// Tinted mini stat (Airbnb style): subtle background with tinted text
private struct MiniStat: View {
    let title: String
    let value: Double
    let currency: String
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(tint)
            Text(value, format: .currency(code: currency))
                .font(.footnote.weight(.semibold))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.10))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Filter Sheet
private struct FilterSheet: View {
    let types: [String]
    @Binding var selected: String?
    var onClose: () -> Void
    var onClear: () -> Void
    @State private var query: String = ""
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section("Type") {
                    Button {
                        withAnimation(.snappy) { selected = nil }
                        Haptics.selection()
                    } label: {
                        HStack {
                            Text("All").bold()
                            Spacer()
                            if selected == nil { Image(systemName: "checkmark").foregroundColor(.airbnbPrimary) }
                        }
                    }
                    .buttonStyle(.plain)
                    let filtered = types.filter { query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? true : $0.localizedCaseInsensitiveContains(query) }
                    ForEach(filtered, id: \.self) { t in
                        Button {
                            withAnimation(.snappy) { selected = t }
                            Haptics.selection()
                        } label: {
                            HStack {
                                Text(t)
                                Spacer()
                                if selected == t { Image(systemName: "checkmark").foregroundColor(.airbnbPrimary) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .listStyle(.insetGrouped)
            HStack(spacing: 12) {
                Button(action: { onClear(); onClose() }) {
                    Text("Clear filters").bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.subtleSeparator))
                }
                .buttonStyle(PressableButtonStyle())
                Button(action: onClose) {
                    Text("Apply").bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(LinearGradient.airbnbAccent))
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
                StatPill(title: "Net income", value: totalNet, currency: currency)
                StatPill(title: "Tax paid", value: totalTax, currency: currency)
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
        .tilt(amount: 0.35)
        .accessibilityElement(children: .combine)
    }
}

// Trend/Sparkline removed per new design

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
                ZStack {
                    Circle().fill(Color.airbnbPrimary.opacity(0.10))
                    Image(systemName: "tag")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LinearGradient.airbnbAccent)
                }
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.subtleSeparator, lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(income.incomeTag.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text("\(income.incomeType.name) • \(DateFormatter.dayMonYear.string(from: income.creditedDate))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(income.amount, format: .currency(code: income.currency))
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                        HStack(spacing: 6) {
                            MiniStat(title: "Net", value: max(0, income.amount - income.taxPaid), currency: income.currency, tint: .airbnbSuccess)
                            MiniStat(title: "Tax", value: income.taxPaid, currency: income.currency, tint: .airbnbPrimary)
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                        .opacity(0.6)
                        .padding(.top, 2)
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
            Circle().fill(Color.airbnbPrimary.opacity(0.12)).frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.subtleSeparator).frame(width: 120, height: 16)
                RoundedRectangle(cornerRadius: 4).fill(Color.subtleSeparator).frame(width: 180, height: 14)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.subtleSeparator).frame(width: 80, height: 18)
                HStack(spacing: 6) {
                    Capsule().fill(Color.subtleSeparator).frame(width: 64, height: 22)
                    Capsule().fill(Color.subtleSeparator).frame(width: 54, height: 22)
                }
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

// Sparkline removed per new design

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
