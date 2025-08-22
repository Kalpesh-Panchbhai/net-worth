import SwiftUI

// MARK: - Shimmer
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    // Stronger highlight in light mode for visibility, softer in dark mode
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
                    .blendMode(colorScheme == .dark ? .screen : .overlay)
                    .mask(content)
                    .frame(width: width + 200, height: height)
                    .offset(x: phase * (width + 200))
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { phase = 1 }
            }
    }
}

extension View {
    func shimmer(active: Bool = true) -> some View {
        self.modifier(active ? Shimmer() : Shimmer())
    }
}
