import SwiftUI

struct WatchlistAccountsView: View {
    let userId: Int
    let watchlist: WatchlistSummary
    @StateObject private var vm: WatchAccountsController
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"
    @State private var pendingDelete: AccountSummary? = nil
    @State private var showAddSheet: Bool = false
    @State private var addingAccountId: Int? = nil
    @State private var removingAccountId: Int? = nil
    @State private var showReportsModal = false
    // Micro-interactions for toolbar button
    @State private var breathe = false
    @State private var rippleTrigger = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var lookup: LookupStore

    init(userId: Int, watchlist: WatchlistSummary) {
        self.userId = userId
        self.watchlist = watchlist
        _vm = StateObject(wrappedValue: WatchAccountsController(userId: userId, watchId: watchlist.id))
    }

    var body: some View {
        let isAll = watchlist.name.trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveCompare("All") == .orderedSame
        ScrollView {
            AccountsSectionedList(
                items: vm.items,
                currency: defaultCurrencyCode.uppercased(),
                isLoading: vm.isLoading,
                enableDelete: !isAll,
                onDelete: isAll ? nil : { item in
                    Haptics.selection()
                    pendingDelete = item
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.bottom, LayoutConstants.tabBarHeight + LayoutConstants.fabBottomMargin + LayoutConstants.fabSize + 150)
        }
        .fabOverlay(
            icon: "plus",
            accessibilityLabel: "Add account to watch",
            isVisible: watchlist.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare("All") != .orderedSame
        ) {
            Haptics.selection()
            showAddSheet = true
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle(watchlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { trendToolbarButton }
        }
        .navigationDestination(for: AccountSummary.self) { account in
            AccountDetailView(account: account)
        }
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollIndicators(.hidden)
        .task {
            vm.attachStore(lookup)
            await vm.load()
        }
        .refreshable { await vm.refresh() }
        .onChange(of: vm.errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            banners.showError(message: message, retryTitle: "Retry", retry: { Task { await vm.refresh() } })
        }
        .alert(item: $pendingDelete) { item in
            Alert(
                title: Text("Remove from watch?"),
                message: Text("This will remove \(item.name) from \(watchlist.name)."),
                primaryButton: .destructive(Text("Remove")) {
                    Task {
                        let ok = await vm.deleteFromWatch(item)
                        if ok {
                            Haptics.success()
                        } else {
                            Haptics.softImpact()
                            let msg = vm.errorMessage ?? "Failed to remove from watch."
                            banners.showError(
                                message: msg,
                                retryTitle: "Retry",
                                retry: { Task { _ = await vm.deleteFromWatch(item) } }
                            )
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                List {
                    Section("Add to watchlist") {
                        ForEach(lookup.accounts, id: \.id) { acc in
                            let isMember = vm.items.contains(where: { $0.id == acc.id })
                            if isMember {
                                Button {
                                    removingAccountId = acc.id
                                    Task {
                                        let success = await vm.deleteFromWatch(acc)
                                        if success {
                                            Haptics.success()
                                            banners.show(
                                                AppBanner(
                                                    icon: "checkmark.circle",
                                                    title: "Removed from watchlist",
                                                    message: "\(acc.name) ← \(watchlist.name)",
                                                    style: .success
                                                )
                                            )
                                        } else {
                                            Haptics.softImpact()
                                            let msg = vm.errorMessage ?? "Failed to remove from watchlist."
                                            banners.showError(message: msg)
                                        }
                                        removingAccountId = nil
                                    }
                                } label: {
                                    HStack {
                                        Text(acc.name)
                                        Spacer()
                                        if removingAccountId == acc.id {
                                            ProgressView().progressViewStyle(.circular)
                                        } else {
                                            Text("Remove")
                                                .font(.footnote.weight(.semibold))
                                                .foregroundColor(.airbnbPrimary)
                                        }
                                    }
                                }
                                .disabled(removingAccountId != nil)
                            } else {
                                Button {
                                    addingAccountId = acc.id
                                    Task {
                                        let success = await vm.addToWatch(acc)
                                        if success {
                                            Haptics.success()
                                            banners.show(AppBanner(icon: "checkmark.circle.fill", title: "Added to watchlist", message: "\(acc.name) → \(watchlist.name)", style: .success))
                                        } else {
                                            Haptics.softImpact()
                                            let msg = vm.errorMessage ?? "Failed to add to watchlist."
                                            banners.showError(message: msg)
                                        }
                                        addingAccountId = nil
                                    }
                                } label: {
                                    HStack {
                                        Text(acc.name)
                                        Spacer()
                                        if addingAccountId == acc.id {
                                            ProgressView().progressViewStyle(.circular)
                                        } else {
                                            Text("Add")
                                                .font(.footnote.weight(.semibold))
                                                .foregroundColor(.airbnbPrimary)
                                        }
                                    }
                                }
                                .disabled(addingAccountId != nil)
                            }
                        }
                    }
                }
                .navigationTitle("Add to watch")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Close") { showAddSheet = false } }
                }
                .task {
                    await lookup.loadAccountsIfNeeded(userId: userId)
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showReportsModal) {
            NavigationStack {
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        Color.canvasBackground.ignoresSafeArea()
                        AssetOverviewCard(
                            preselect: (
                                type: .watchlist,
                                id: watchlist.id,
                                name: watchlist.name
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

                // Ripple ring
                Circle()
                    .stroke(LinearGradient.airbnbAccent, lineWidth: 2)
                    .scaleEffect(rippleTrigger ? 1.7 : 0.9)
                    .opacity(rippleTrigger ? 0.35 : 0.0)
                    .animation(.easeOut(duration: 0.6), value: rippleTrigger)
            }
            .frame(width: 34, height: 34)
            .scaleEffect(reduceMotion ? 1.0 : (breathe ? 1.02 : 0.98))
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathe)
            .onAppear { if !reduceMotion { breathe = true } }
        }
        .buttonStyle(PressableButtonStyle(scale: 0.96))
        .accessibilityLabel("View Trends")
    }
}
