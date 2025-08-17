import SwiftUI

// MARK: - Shimmer
struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [.white.opacity(0.0), .white.opacity(0.22), .white.opacity(0.0)]
                        : [.white.opacity(0.0), .white.opacity(0.6), .white.opacity(0.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.screen)
                .mask(content)
                .offset(x: phase * 180)
            )
            .onAppear { withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { phase = 1 } }
    }
}

extension View {
    func shimmer(active: Bool = true) -> some View {
        self.modifier(active ? Shimmer() : Shimmer())
    }
}
