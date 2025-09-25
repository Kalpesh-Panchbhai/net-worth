import SwiftUI

// MARK: - Floating Action Button (Reusable)
struct FloatingActionButton: View {
    var icon: String
    var action: () -> Void
    var size: CGFloat
    var gradient: LinearGradient
    var shadow: Color
    var shadowRadius: CGFloat
    var shadowYOffset: CGFloat
    var accessibilityLabel: String

    init(
        icon: String = "plus",
        size: CGFloat = 56,
        gradient: LinearGradient = .airbnbAccent,
        shadow: Color = Color.clear,
        shadowRadius: CGFloat = 12,
        shadowYOffset: CGFloat = 6,
        accessibilityLabel: String = "Add",
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.gradient = gradient
        self.shadow = shadow
        self.shadowRadius = shadowRadius
        self.shadowYOffset = shadowYOffset
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle().fill(gradient)
                )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.94))
        .accessibilityLabel(accessibilityLabel)
    }
}
