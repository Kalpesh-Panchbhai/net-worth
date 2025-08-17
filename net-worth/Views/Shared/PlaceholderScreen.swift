import SwiftUI

struct PlaceholderScreen: View {
    let title: String
    let systemImage: String
    let tab: AppTab
    @State private var navCollapsed = false
    @EnvironmentObject private var tabCommands: TabCommandCenter
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    GeometryReader { proxy in
                        Color.clear.preference(key: NavBarOffsetKey.self, value: proxy.frame(in: .named("placeholderScroll")).minY)
                    }
                    .frame(height: 0)
                    ZStack(alignment: .top) {
                        Color.canvasBackground.ignoresSafeArea()
                        VStack(spacing: 16) {
                            Image(systemName: systemImage)
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(LinearGradient.airbnbAccent)
                                .padding(.top, 32)
                            Text(title)
                                .font(.title2).bold()
                                .foregroundColor(.primary)
                            Text("Coming soon")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer(minLength: 400)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    Color.clear.frame(height: 1).id("placeholderBottom")
                }
                .coordinateSpace(name: "placeholderScroll")
                .onChange(of: tabCommands.scrollToBottomRequest) { _, req in
                    guard req == tab else { return }
                    withAnimation(.easeInOut(duration: 0.35)) { proxy.scrollTo("placeholderBottom", anchor: .bottom) }
                    DispatchQueue.main.async { tabCommands.scrollToBottomRequest = nil }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
        }
    }
}
