import SwiftUI
import UIKit

// MARK: - Design Tokens (Airbnb-inspired)
extension Color {
    static let airbnbPrimary = Color(red: 255/255, green: 90/255, blue: 95/255)
    static let elevatedBackground = Color(UIColor.systemBackground)
    static let canvasBackground = Color(UIColor.systemGroupedBackground)
    static let subtleSeparator = Color(UIColor.separator).opacity(0.35)
    static let airbnbSecondary = Color(red: 255/255, green: 56/255, blue: 92/255)
    static let airbnbInk = Color(red: 34/255, green: 34/255, blue: 34/255)
    static let airbnbSuccess = Color(red: 0/255, green: 138/255, blue: 5/255)
}

// Brand Gradient
extension LinearGradient {
    static let airbnbAccent = LinearGradient(
        colors: [.airbnbPrimary, .airbnbSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Elevated Shadow
struct ElevatedShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var radiusLight: CGFloat = 8
    var yLight: CGFloat = 4
    var radiusDark: CGFloat = 10
    var yDark: CGFloat = 6
    func body(content: Content) -> some View {
        content.shadow(
            color: colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06),
            radius: colorScheme == .dark ? radiusDark : radiusLight,
            x: 0,
            y: colorScheme == .dark ? yDark : yLight
        )
    }
}

extension View {
    func elevatedShadow() -> some View { modifier(ElevatedShadow()) }
}
