import SwiftUI

// MARK: - Watchlist
struct WatchlistListView: View {
    @StateObject private var vm: WatchlistController
    @State private var navCollapsed = false
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var tabCommands: TabCommandCenter
    @EnvironmentObject private var lookup: LookupStore
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"
    @State private var showCreate = false
    @State private var createName = ""
    @State private var creating = false
    @State private var pendingDelete: Watchlist? = nil
    @State private var renaming: Watchlist? = nil
    @State private var renameText: String = ""
    @State private var renamingSaving: Bool = false

    init(userId: Int) {
        _vm = StateObject(wrappedValue: WatchlistController(userId: userId))
    }

    // FloatingAddButton moved to Shared/FloatingActionButton.swift

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .top) {
                    Color.canvasBackground.ignoresSafeArea()
                    ScrollView {
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: NavBarOffsetKey.self,
                                value: geo.frame(in: .named("watchlistScroll")).minY
                            )
                        }
                        .frame(height: 0)

                        VStack(spacing: 16) {
                            if vm.isLoading && vm.items.isEmpty {
                                ForEach(0..<5, id: \.self) { _ in
                                    WatchlistRowCard.placeholder()
                                }
                                .shimmer()
                            } else if vm.items.isEmpty {
                                EmptyStateCard(text: "No watchlists yet")
                            } else {
                                WatchlistRowsList(
                                    items: vm.items,
                                    currency: defaultCurrencyCode.uppercased(),
                                    onRename: { item in
                                        renaming = item
                                        renameText = item.name
                                        Haptics.selection()
                                    },
                                    onDelete: { item in
                                        pendingDelete = item
                                        Haptics.selection()
                                    }
                                )
                            }

                            let bottomPad =
                                LayoutConstants.tabBarHeight + LayoutConstants.fabBottomMargin
                                + LayoutConstants.fabSize + 24
                            Color.clear.frame(height: bottomPad).id("watchBottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(
                            .bottom,
                            LayoutConstants.tabBarHeight + LayoutConstants.fabBottomMargin
                                + LayoutConstants.fabSize + 24)
                    }
                    .background(ScrollToTopEnabler())
                    .scrollIndicators(.hidden)
                    .coordinateSpace(name: "watchlistScroll")
                }
                .onChange(of: tabCommands.scrollToBottomRequest) { _, req in
                    guard req == .watchlist else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo("watchBottom", anchor: .bottom)
                    }
                    DispatchQueue.main.async { tabCommands.scrollToBottomRequest = nil }
                }
            }
            .navigationTitle("Watchlists")
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
        }
        .fabOverlay(accessibilityLabel: "Add watchlist") {
            Haptics.selection()
            showCreate = true
        }
        .alert(item: $pendingDelete) { item in
            Alert(
                title: Text("Delete watchlist?"),
                message: Text("This will remove \(item.name)."),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        let ok = await vm.delete(item)
                        if ok {
                            Haptics.success()
                        } else {
                            Haptics.softImpact()
                            let msg = vm.errorMessage ?? "Failed to delete watchlist."
                            banners.showError(
                                message: msg, retryTitle: "Retry",
                                retry: { Task { _ = await vm.delete(item) } })
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear { vm.attachStore(lookup) }
        .task { await vm.load() }
        .refreshable { await vm.refresh() }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.items)
        .onChange(of: vm.errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            // Suppress banners for pull-to-refresh if we already have data
            guard vm.items.isEmpty else { return }
            banners.showError(
                message: message, retryTitle: "Retry", retry: { Task { await vm.refresh() } })
        }
        .sheet(isPresented: $showCreate) {
            ZStack {
                Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 16) {
                            SettingsGroup(showHeader: false) {
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("Name", text: $createName)
                                        .textInputAutocapitalization(.words)
                                        .disableAutocorrection(true)
                                    Rectangle().fill(Color.subtleSeparator).frame(height: 0.5)
                                        .padding(.horizontal, 0)
                                }
                                .padding(.horizontal, 4)
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                        .background(Color.clear)
                    }
                    .navigationTitle("New")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showCreate = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(creating ? "Saving…" : "Save") {
                                let name = createName.trimmingCharacters(
                                    in: .whitespacesAndNewlines)
                                guard !name.isEmpty else { return }
                                creating = true
                                Task {
                                    await vm.create(name: name)
                                    creating = false
                                    showCreate = false
                                    createName = ""
                                    Haptics.success()
                                }
                            }
                            .disabled(
                                createName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    || creating)
                        }
                    }
                    .toolbarBackground(Color.canvasBackground, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                }
            }
            .presentationDetents([.height(220), .medium, .large])
            .interactiveDismissDisabled(creating)
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $renaming) { item in
            ZStack {
                Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 16) {
                            SettingsGroup(showHeader: false) {
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("Name", text: $renameText)
                                        .textInputAutocapitalization(.words)
                                        .disableAutocorrection(true)
                                    Rectangle().fill(Color.subtleSeparator).frame(height: 0.5)
                                        .padding(.horizontal, 0)
                                }
                                .padding(.horizontal, 4)
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                        .background(Color.clear)
                    }
                    .navigationTitle("Rename")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { renaming = nil }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(renamingSaving ? "Saving…" : "Save") {
                                let name = renameText.trimmingCharacters(
                                    in: .whitespacesAndNewlines)
                                guard !name.isEmpty else { return }
                                renamingSaving = true
                                Task {
                                    let ok = await vm.rename(item, to: name)
                                    if ok {
                                        Haptics.success()
                                        renaming = nil
                                    } else {
                                        Haptics.softImpact()
                                        let msg = vm.errorMessage ?? "Failed to update."
                                        banners.showError(
                                            message: msg, retryTitle: "Retry",
                                            retry: { Task { _ = await vm.rename(item, to: name) } })
                                    }
                                    renamingSaving = false
                                }
                            }
                            .disabled(
                                renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    || renamingSaving)
                        }
                    }
                    .toolbarBackground(Color.canvasBackground, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                }
            }
            .presentationDetents([.height(220), .medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(renamingSaving)
        }
    }
}

// MARK: - Summary Card
private struct WatchSummaryCard: View {
    let totalCurrent: Double
    let totalInvested: Double
    let change: Double  // current - invested
    let changeVsPrev: Double  // current - previous
    let changePercent: Double?
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total value")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(totalCurrent, format: .currency(code: currency))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(LinearGradient.airbnbAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.45), value: totalCurrent)
            }
            HStack(spacing: 8) {
                Pill(
                    title: "Invested", value: totalInvested, currency: currency, tint: .secondary,
                    isNeutral: true)
                Pill(
                    title: change >= 0 ? "P/L" : "Loss", value: abs(change), currency: currency,
                    tint: change >= 0 ? .airbnbSuccess : .red)
                if let pct = changePercent {
                    ChangePill(change: changeVsPrev, percent: pct)
                }
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

private struct Pill: View {
    let title: String
    let value: Double
    let currency: String
    var tint: Color = .airbnbPrimary
    var isNeutral: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value, format: .currency(code: currency))
                .font(.headline)
                .foregroundColor(isNeutral ? .secondary : tint)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.45), value: value)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule(style: .continuous)
                .fill((isNeutral ? Color.secondary.opacity(0.08) : tint.opacity(0.10)))
        )
    }
}

private struct ChangePill: View {
    let change: Double
    let percent: Double  // -0.12 ... 0.34
    private var isUp: Bool { change >= 0 }
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
            Text(String(format: "%@%.2f%%", isUp ? "+" : "-", abs(percent * 100)))
        }
        .font(.subheadline.weight(.semibold))
        .foregroundColor(isUp ? .airbnbSuccess : .red)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Capsule().fill((isUp ? Color.airbnbSuccess : .red).opacity(0.12)))
    }
}

// MARK: - List
private struct WatchlistRowsList: View {
    let items: [Watchlist]
    let currency: String
    var onRename: (Watchlist) -> Void
    var onDelete: (Watchlist) -> Void
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(items, id: \.id) { item in
                WatchlistRowCard(
                    item: item,
                    currency: currency,
                    onRename: item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        .localizedCaseInsensitiveCompare("All") == .orderedSame ? nil : onRename,
                    onDelete: item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        .localizedCaseInsensitiveCompare("All") == .orderedSame ? nil : onDelete
                )
            }
        }
    }
}

private struct WatchlistRowCard: View {
    let item: Watchlist
    let currency: String
    var onRename: ((Watchlist) -> Void)? = nil
    var onDelete: ((Watchlist) -> Void)? = nil

    private var delta: Double { item.value.currentValue - item.value.invested }
    private var deltaPercentText: String? {
        let denom = abs(item.value.invested)
        guard denom > 0 else { return nil }
        return (delta / denom).formatted(.percent.precision(.fractionLength(1)))
    }
    private var dayChange: Double { item.value.currentValue - item.value.previousValue }
    private var dayPercentText: String? {
        let denom = abs(item.value.previousValue)
        guard denom > 0 else { return nil }
        return (dayChange / denom).formatted(.percent.precision(.fractionLength(1)))
    }

    var body: some View {
        Button(action: { Haptics.softImpact() }) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.name)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(0)
                        Spacer(minLength: 8)
                        if item.totalAccount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "rectangle.stack")
                                    .font(.caption)
                                Text("\(item.totalAccount)")
                                    .font(.caption2.bold())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(.secondary)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(Capsule().fill(Color.secondary.opacity(0.12)))
                            .fixedSize()
                            .layoutPriority(2)
                        }
                    }
                    HStack(spacing: 10) {
                        ValueLabel(
                            title: "Current", value: item.value.currentValue, currency: currency,
                            emphasize: true)
                        Divider().frame(height: 18)
                        ValueLabel(
                            title: "Invested", value: item.value.invested, currency: currency)
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 8) {
                    WideStatPill(
                        icon: delta >= 0 ? "arrow.up.right" : "arrow.down.right",
                        value: abs(delta),
                        currency: currency,
                        percent: deltaPercentText,
                        tint: delta >= 0 ? .airbnbSuccess : .red
                    )
                    if dayPercentText != nil {
                        WideStatPill(
                            icon: dayChange >= 0 ? "arrow.up.right" : "arrow.down.right",
                            value: abs(dayChange),
                            currency: currency,
                            percent: dayPercentText,
                            tint: dayChange >= 0 ? .airbnbSuccess : .red
                        )
                    }
                }
                .layoutPriority(1)
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
        .contextMenu {
            if let onRename {
                Button {
                    onRename(item)
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
            }
            if let onDelete {
                Button(role: .destructive) {
                    onDelete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

private struct ValueLabel: View {
    let title: String
    let value: Double
    let currency: String
    var emphasize: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(.secondary)
            Text(CurrencyShort.shortString(value, currency: currency))
                .font(emphasize ? .headline.weight(.semibold) : .subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
        }
    }
}

// Local custom pills removed in favor of shared WideStatPill

// MARK: - Placeholders
extension WatchlistRowCard {
    fileprivate static func placeholder() -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                    width: 120, height: 16)
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                        width: 90, height: 14)
                    RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                        width: 90, height: 14)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                    width: 100, height: 18)
                RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(
                    width: 80, height: 14)
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
