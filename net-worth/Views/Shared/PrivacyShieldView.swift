import SwiftUI

struct PrivacyShieldView: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            // Light, airy background inspired by Airbnb
            LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.98, green: 0.98, blue: 0.98)
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
                    // Frosted circular badge
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 132, height: 132)
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)

                    // Animated gradient ring (subtle on light)
                    Circle()
                        .trim(from: 0.05, to: 1.0)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.airbnbPrimary, .airbnbSecondary, .airbnbPrimary]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(animate ? 360 : 0))
                        .animation(.linear(duration: 3.0).repeatForever(autoreverses: false), value: animate)
                        .opacity(0.65)

                    // Icon with subtle glow
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .blur(radius: 10)
                            .frame(width: 70, height: 70)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.airbnbInk)
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                }

                Text("Hidden for privacy")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.airbnbInk.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous).fill(Color.black.opacity(0.05))
                    )
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
