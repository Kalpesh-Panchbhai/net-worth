import SwiftUI

struct WatchlistAccountsView: View {
    let userId: Int
    let watchlist: Watchlist
    @StateObject private var vm: WatchAccountsController
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var lookup: LookupStore

    init(userId: Int, watchlist: Watchlist) {
        self.userId = userId
        self.watchlist = watchlist
        _vm = StateObject(wrappedValue: WatchAccountsController(userId: userId, watchId: watchlist.id))
    }

    var body: some View {
        ScrollView {
            AccountsSectionedList(
                items: vm.items,
                currency: defaultCurrencyCode.uppercased(),
                isLoading: vm.isLoading,
                enableDelete: false
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
    }
}
