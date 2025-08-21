import SwiftUI
import UIKit

// MARK: - Design Tokens (Airbnb-inspired)
extension Color {
    static let airbnbPrimary = Color(red: 255/255, green: 90/255, blue: 95/255)
    // Canvas for screens
    // Light: pure white canvas, Dark: grouped canvas
    static let canvasBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.systemGroupedBackground : UIColor.systemBackground
    })
    // Elevated card background
    // Light: pure surface (systemBackground) for crisp white cards
    // Dark: secondarySystemGroupedBackground for separation from canvas
    static let elevatedBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.secondarySystemGroupedBackground : UIColor.systemBackground
    })
    // Optional alt surface for nested cards
    // Light: secondary grouped for subtle contrast, Dark: tertiary grouped for deeper nesting
    static let elevatedBackgroundAlt = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.tertiarySystemGroupedBackground : UIColor.secondarySystemGroupedBackground
    })
    // Subtle hairline separator (stronger in Dark Mode for crisper borders)
    static let subtleSeparator = Color(UIColor { trait in
        UIColor.separator.withAlphaComponent(trait.userInterfaceStyle == .dark ? 0.55 : 0.22)
    })
    // Neutral placeholder fill for preview blocks/skeletons
    static let placeholderFill = Color(UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return UIColor.tertiarySystemFill // subtle on dark
        } else {
            return UIColor.systemBackground // pure white in Light Mode to avoid gray blocks
        }
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

// MARK: - Global Layout Tokens
enum LayoutConstants {
    // Custom tab bar height used across the app
    static let tabBarHeight: CGFloat = 50
    // Floating Action Button default paddings
    static let fabTrailing: CGFloat = 20
    // Keep FAB close to the tab bar; since content sits above the safe-area inset
    // (RootView uses .safeAreaInset for the tab bar), a small margin is sufficient.
    static let fabBottomMargin: CGFloat = 16
    // Standard FAB diameter used by FloatingActionButton
    static let fabSize: CGFloat = 56
    // Standard min height for elevated cards (summary and list rows)
    static let cardMinHeight: CGFloat = 120
    // Standard card corner radius
    static let cardCornerRadius: CGFloat = 14
    // Fixed width for stat pills to align columns across rows
    static let statPillWidth: CGFloat = 176
}

extension View {
    // Standardized padding for FloatingActionButton overlay so it hugs above the tab bar
    func fabPadding() -> some View {
        self
            .padding(.trailing, LayoutConstants.fabTrailing)
            .padding(.bottom, LayoutConstants.fabBottomMargin)
    }
    // Overlay helper that anchors the FAB to the content area's bottom-trailing.
    // RootView adds the tab bar via .safeAreaInset. To sit just above it,
    // lift by tabBarHeight + a small margin.
    func fabOverlay(icon: String = "plus", accessibilityLabel: String = "Add", isVisible: Bool = true, action: @escaping () -> Void) -> some View {
        overlay(alignment: .bottomTrailing) {
            if isVisible {
                FloatingActionButton(icon: icon, accessibilityLabel: accessibilityLabel, action: action)
                    .padding(.trailing, LayoutConstants.fabTrailing)
                    .padding(.bottom, LayoutConstants.tabBarHeight + LayoutConstants.fabBottomMargin)
            }
        }
    }
}
