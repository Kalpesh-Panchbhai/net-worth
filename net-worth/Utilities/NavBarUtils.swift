import SwiftUI

// MARK: - Nav Bar Utilities
struct NavBarOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

extension View {
    @ViewBuilder
    func airbnbNavBarBackground(collapsed: Bool) -> some View {
        // Always show a navigation bar background so content never bleeds
        // under the status bar/large title. This fixes header overlap across views.
        self
            .toolbarBackground(Color.canvasBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}
