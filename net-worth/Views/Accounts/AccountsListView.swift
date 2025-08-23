import SwiftUI

struct AccountsListView: View {
    @StateObject private var vm: AccountsController
    @State private var navCollapsed = false
    @State private var showCreateSheet = false
    @State private var pendingDelete: Account? = nil
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var tabCommands: TabCommandCenter
    @EnvironmentObject private var lookup: LookupStore

    init(userId: Int) {
        _vm = StateObject(wrappedValue: AccountsController(userId: userId))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .top) {
                    Color.canvasBackground.ignoresSafeArea()
                    ScrollView {
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: NavBarOffsetKey.self,
                                value: geo.frame(in: .named("accountsScroll")).minY
                            )
                        }
                        .frame(height: 0)

                        AccountsSectionedList(
                            items: vm.items,
                            currency: defaultCurrencyCode.uppercased(),
                            isLoading: vm.isLoading,
                            enableDelete: true,
                            onDelete: { item in
                                Haptics.selection()
                                pendingDelete = item
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, LayoutConstants.tabBarHeight + 24)
                        Color.clear.frame(height: LayoutConstants.tabBarHeight + 24).id("accountsBottom")
                    }
                    .background(ScrollToTopEnabler())
                    .scrollIndicators(.hidden)
                    .coordinateSpace(name: "accountsScroll")
                }
                .onChange(of: tabCommands.scrollToBottomRequest) { _, value in
                    guard value == .accounts else { return }
                    withAnimation { proxy.scrollTo("accountsBottom", anchor: .bottom) }
                    DispatchQueue.main.async { tabCommands.scrollToBottomRequest = nil }
                }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
            // Custom search bar used instead of .searchable for brand styling
        }
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
                title: Text("Delete account?"),
                message: Text("This will remove \(item.name)."),
                primaryButton: .destructive(Text("Delete")) {
                    Task { _ = await vm.delete(item) }
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showCreateSheet) {
            NavigationStack {
                CreateAccountView(userId: vm.userId)
                    .environmentObject(lookup)
                    .environmentObject(banners)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fabOverlay(icon: "plus", accessibilityLabel: "Add account") {
            showCreateSheet = true
        }
    }
}
