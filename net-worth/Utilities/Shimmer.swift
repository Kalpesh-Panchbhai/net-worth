import SwiftUI

// MARK: - Shimmer
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let stripeW = max(w * 0.45, 180)
                    let highlight = colorScheme == .dark ? Color.white.opacity(0.28) : Color.white.opacity(0.65)
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: highlight, location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: stripeW, height: h * 2)
                    .rotationEffect(.degrees(20))
                    .offset(x: phase * (w + stripeW), y: 0)
                    .allowsHitTesting(false)
                }
            }
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) { phase = 1 }
            }
    }
}

extension View {
    func shimmer(active: Bool = true) -> some View {
        self.modifier(active ? Shimmer() : Shimmer())
    }
}
