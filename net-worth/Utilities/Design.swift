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
            return UIColor.secondarySystemFill // light neutral so shimmer is visible in Light Mode
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

// Expose elevatedShadow globally
extension View {
    func elevatedShadow() -> some View { modifier(ElevatedShadow()) }
}

// Reusable elevated card background helper
extension View {
    func elevatedCardBackground(cornerRadius: CGFloat = 16) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }
}

// MARK: - Airbnb-style Search Bar
public struct AppSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }
}

// MARK: - Filter Chip
public struct FilterChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isOn ? .white : .airbnbPrimary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                ZStack {
                    Capsule().fill(Color.airbnbPrimary.opacity(0.12))
                    if isOn { Capsule().fill(LinearGradient.airbnbAccent) }
                }
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Wide Stat Pill (value + optional percent)
public struct WideStatPill: View {
    let icon: String
    let value: Double
    let currency: String
    let percent: String?
    let tint: Color
    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2.weight(.bold))
            Text(CurrencyShort.shortString(value, currency: currency))
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            if let p = percent, !p.isEmpty {
                Text("•").font(.caption2.weight(.semibold))
                Text(p)
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
        }
        .foregroundColor(tint)
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(
            Capsule().fill(tint.opacity(0.12))
        )
    }
}

// MARK: - Labeled Currency Pill (title + full currency value)
public struct LabeledCurrencyPill: View {
    public let title: String
    public let value: Double
    public let currency: String
    public var tint: Color
    public init(title: String, value: Double, currency: String, tint: Color) {
        self.title = title
        self.value = value
        self.currency = currency
        self.tint = tint
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value, format: .currency(code: currency))
                .font(.headline)
                .foregroundColor(tint)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.08))
        )
    }
}

// MARK: - Empty State Card (reusable)
public struct EmptyStateCard: View {
    public let text: String
    public var icon: String
    public var iconFont: Font
    public init(text: String, icon: String = "tray", iconFont: Font = .title2) {
        self.text = text
        self.icon = icon
        self.iconFont = iconFont
    }
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(iconFont)
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.subtleSeparator.opacity(0.12), lineWidth: 1)
        )
        .elevatedShadow()
    }
}

// duplicate elevatedShadow extension removed (already declared above)

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
