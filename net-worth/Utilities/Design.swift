import SwiftUI
import UIKit

// MARK: - Design Tokens (Airbnb-inspired)
extension Color {
    static let airbnbPrimary = Color(red: 255/255, green: 90/255, blue: 95/255)
    // Canvas for screens and grouped lists
    static let canvasBackground = Color(UIColor.systemGroupedBackground)
    // Elevated card background; use secondary grouped background to lift from canvas in Dark Mode
    static let elevatedBackground = Color(UIColor.secondarySystemGroupedBackground)
    // Optional alt surface for nested cards
    static let elevatedBackgroundAlt = Color(UIColor.tertiarySystemGroupedBackground)
    // Subtle hairline separator (stronger in Dark Mode for crisper borders)
    static let subtleSeparator = Color(UIColor { trait in
        UIColor.separator.withAlphaComponent(trait.userInterfaceStyle == .dark ? 0.55 : 0.35)
    })
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
    var radiusDark: CGFloat = 12
    var yDark: CGFloat = 7
    func body(content: Content) -> some View {
        Group {
            if colorScheme == .dark {
                // Layered shadows improve elevation perception in Dark Mode
                content
                    .shadow(color: Color.white.opacity(0.08), radius: 1, x: 0, y: 1)
                    .shadow(color: Color.black.opacity(0.45), radius: radiusDark + 6, x: 0, y: yDark)
            } else {
                content
                    .shadow(color: Color.black.opacity(0.10), radius: radiusLight, x: 0, y: yLight)
            }
        }
    }
}

extension View {
    func elevatedShadow() -> some View { modifier(ElevatedShadow()) }
}
