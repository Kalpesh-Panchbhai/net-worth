import SwiftUI
import UIKit
import Network
import Combine

// MARK: - Haptics & Interactions
enum Haptics {
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    static func softImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var opacity: Double = 0.98
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? opacity : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Global Network Monitor
final class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.isConnected = (path.status == .satisfied) }
        }
        monitor.start(queue: queue)
    }
    deinit { monitor.cancel() }
}

// MARK: - Tab Command Center (e.g., scroll to bottom on retap)
final class TabCommandCenter: ObservableObject {
    @Published var scrollToBottomRequest: AppTab? = nil
    // Programmatic tab navigation requests (set a value to request switch, then reset to nil)
    @Published var navigateToTab: AppTab? = nil
}
