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

// MARK: - Global Offline Banner
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.airbnbPrimary.opacity(0.12))
                Image(systemName: "wifi.exclamationmark")
                    .foregroundColor(.airbnbPrimary)
            }
            .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text("No internet connection").font(.subheadline).bold()
                Text("You're offline or the connection was lost.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            Rectangle().fill(Color.elevatedBackground)
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.subtleSeparator).frame(height: 0.5)
        }
    }
}
