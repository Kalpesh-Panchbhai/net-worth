import SwiftUI

struct PrivacyShieldView: View {
    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        ZStack {
            // Dynamic background that follows Light/Dark mode
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.secondarySystemBackground),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft brand accent glow (very subtle)
            RadialGradient(
                colors: [Color.airbnbSecondary.opacity(0.06), .clear],
                center: .topLeading,
                startRadius: 2,
                endRadius: 520
            )
            .ignoresSafeArea()

            // Centerpiece: frosted badge + animated gradient ring
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.tertiarySystemBackground).opacity(0.22))
                        .blur(radius: 10)
                        .frame(width: 70, height: 70)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.airbnbPrimary)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
            }
            .accessibilityHidden(true)
        }
        // No interaction is needed; this prevents any accidental taps
        .allowsHitTesting(false)
        // Avoids VoiceOver reading content while shield is visible
        .accessibilityHidden(true)
        .onAppear { animate = true }
    }
}
