import SwiftUI

// MARK: - Watchlist
struct WatchlistListView: View {
    @StateObject private var vm: WatchlistController
    @State private var navCollapsed = false
    @State private var path: [WatchlistSummary] = []
    @State private var showFab: Bool = true
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var tabCommands: TabCommandCenter
    @EnvironmentObject private var lookup: LookupStore
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"
    @State private var showCreate = false
    @State private var createName = ""
    @State private var creating = false
    @State private var pendingDelete: WatchlistSummary? = nil
    @State private var renaming: WatchlistSummary? = nil
    @State private var renameText: String = ""
    @State private var renamingSaving: Bool = false

    init(userId: Int) {
        _vm = StateObject(wrappedValue: WatchlistController(userId: userId))
    }

    @ViewBuilder
    private var listContent: some View {
        VStack(spacing: 16) {
            if vm.isLoading && vm.items.isEmpty {
                ForEach(0..<5, id: \.self) { _ in
                    AssetRowCard.placeholder()
                }
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
    }
    
    // MARK: - Sheets
    @ViewBuilder
    private var createSheetView: some View {
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
                            let name = createName.trimmingCharacters(in: .whitespacesAndNewlines)
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
                        .disabled(createName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || creating)
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

    @ViewBuilder
    private func renameSheetView(item: WatchlistSummary) -> some View {
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
                            let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
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
                        .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || renamingSaving)
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
    // FloatingAddButton moved to Shared/FloatingActionButton.swift

    var body: some View {
        NavigationStack(path: $path) {
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

                        listContent
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
                .fabOverlay(accessibilityLabel: "Add watchlist", isVisible: showFab) {
                    Haptics.selection()
                    showCreate = true
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
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
            .navigationDestination(for: WatchlistSummary.self) { item in
                WatchlistAccountsView(userId: vm.userId, watchlist: item)
                    .onAppear { showFab = false }
                    .onDisappear { showFab = path.isEmpty }
            }
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
        .task {
            vm.attachStore(lookup)
            await vm.load()
        }
        .refreshable { await vm.refresh() }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.items)
        .onChange(of: vm.errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            // Suppress banners for pull-to-refresh if we already have data
            guard vm.items.isEmpty else { return }
            banners.showError(
                message: message, retryTitle: "Retry", retry: { Task { await vm.refresh() } })
        }
        .sheet(isPresented: $showCreate) { createSheetView }
        .sheet(item: $renaming) { item in renameSheetView(item: item) }
        .onChange(of: path) { _, newPath in
            showFab = newPath.isEmpty
        }
    }
}
// MARK: - List
private struct WatchlistRowsList: View {
    let items: [WatchlistSummary]
    let currency: String
    var onRename: (WatchlistSummary) -> Void
    var onDelete: (WatchlistSummary) -> Void
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(items, id: \.id) { item in
                NavigationLink(value: item) {
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
}

private struct WatchlistRowCard: View {
    let item: WatchlistSummary
    let currency: String
    var onRename: ((WatchlistSummary) -> Void)? = nil
    var onDelete: ((WatchlistSummary) -> Void)? = nil

    private var delta: Double { item.currentDayValue - item.invested }
    private var deltaPercentText: String? {
        let denom = abs(item.invested)
        guard denom > 0 else { return nil }
        return (delta / denom).formatted(.percent.precision(.fractionLength(1)))
    }
    private var dayChange: Double { item.currentDayValue - item.previousDayValue }
    private var dayPercentText: String? {
        let denom = abs(item.previousDayValue)
        guard denom > 0 else { return nil }
        return (dayChange / denom).formatted(.percent.precision(.fractionLength(1)))
    }

    var body: some View {
        AssetRowCard(
            name: item.name,
            current: item.currentDayValue,
            invested: item.invested,
            previous: item.previousDayValue,
            currency: currency,
            countBadge: item.totalAccount > 0 ? item.totalAccount : nil
        )
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

// Local custom pills removed in favor of shared WideStatPill

// (Unified placeholder now provided by AssetRowCard.placeholder())
