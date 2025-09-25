import SwiftUI

// MARK: - Nav Bar Utilities
struct NavBarOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

extension View {
    @ViewBuilder
    func airbnbNavBarBackground(collapsed: Bool) -> some View {
        // Simplified navigation bar background - let system handle appearance
        self
    }
}
