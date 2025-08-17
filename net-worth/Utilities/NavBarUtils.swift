import SwiftUI

// MARK: - Nav Bar Utilities
struct NavBarOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

extension View {
    @ViewBuilder
    func airbnbNavBarBackground(collapsed: Bool) -> some View {
        if collapsed {
            self
                .toolbarBackground(LinearGradient.airbnbAccent.opacity(0.07), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            self
                .toolbarBackground(Color.canvasBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
