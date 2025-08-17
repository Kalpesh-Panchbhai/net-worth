import SwiftUI
import CoreMotion

final class MotionManager: ObservableObject {
    private let manager = CMMotionManager()
    @Published var roll: Double = 0
    @Published var pitch: Double = 0
    
    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 40.0
        manager.startDeviceMotionUpdates(to: .main) { data, _ in
            guard let d = data else { return }
            self.roll = d.attitude.roll
            self.pitch = d.attitude.pitch
        }
    }
    
    func stop() { manager.stopDeviceMotionUpdates() }
}

struct Tilt: ViewModifier {
    @StateObject private var motion = MotionManager()
    @Environment(\.colorScheme) private var colorScheme
    var amount: Double = 0.35
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(deg(motion.pitch) * amount), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(deg(motion.roll) * amount), axis: (x: 0, y: 1, z: 0))
            .shadow(color: (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.08)), radius: 10, x: motion.roll * 6, y: motion.pitch * 6)
            .onAppear { motion.start() }
            .onDisappear { motion.stop() }
    }
    
    private func deg(_ rad: Double) -> Double { rad * 180 / .pi }
}

extension View {
    func tilt(amount: Double = 0.35) -> some View { modifier(Tilt(amount: amount)) }
}
