import SwiftUI

struct WatchlistAccountsView: View {
    let userId: Int
    let watchlist: Watchlist
    @StateObject private var vm: WatchAccountsController
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"
    @State private var pendingDelete: Account? = nil
    @State private var showAddSheet: Bool = false
    @State private var addingAccountId: Int? = nil
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var lookup: LookupStore

    init(userId: Int, watchlist: Watchlist) {
        self.userId = userId
        self.watchlist = watchlist
        _vm = StateObject(wrappedValue: WatchAccountsController(userId: userId, watchId: watchlist.id))
    }

    var body: some View {
        ScrollView {
            let isAll = watchlist.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare("All") == .orderedSame
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
            Color.clear.frame(height: LayoutConstants.tabBarHeight + 24)
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle(watchlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .fabOverlay(
            icon: "plus",
            accessibilityLabel: "Add account to watch",
            isVisible: watchlist.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare("All") != .orderedSame
        ) {
            Haptics.selection()
            showAddSheet = true
        }
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
                                HStack {
                                    Text(acc.name)
                                    Spacer()
                                    Label("Added", systemImage: "checkmark.circle.fill")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                                .disabled(true)
                            } else {
                                Button {
                                    addingAccountId = acc.id
                                    Task {
                                        do {
                                            _ = try await RestClient().createWatchAccount(accountId: acc.id, watchId: watchlist.id)
                                            Haptics.success()
                                            banners.show(AppBanner(icon: "checkmark.circle.fill", title: "Added to watchlist", message: "\(acc.name) → \(watchlist.name)", style: .success))
                                            // Refresh to update membership
                                            await vm.refresh()
                                        } catch let api as APIError {
                                            Haptics.softImpact()
                                            let msg = api.errorDescription ?? "Failed to add to watchlist."
                                            banners.showError(message: msg)
                                        } catch {
                                            Haptics.softImpact()
                                            banners.showError(message: error.localizedDescription)
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
    }
}
