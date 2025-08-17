import SwiftUI

struct PlaceholderScreen: View {
    let title: String
    let systemImage: String
    @State private var navCollapsed = false
    
    var body: some View {
        NavigationStack {
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
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .coordinateSpace(name: "placeholderScroll")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
        }
    }
}
