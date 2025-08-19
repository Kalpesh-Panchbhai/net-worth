import SwiftUI
import UIKit

// Manages a window-level privacy shield that sits above all UI (including sheets)
final class PrivacyShieldManager {
    static let shared = PrivacyShieldManager()
    private init() {}

    private var windows: [ObjectIdentifier: UIWindow] = [:]

    func setVisible(_ visible: Bool) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let existingKeys = Set(scenes.map { ObjectIdentifier($0) })

        // Cleanup stale windows
        for (key, win) in windows where !existingKeys.contains(key) {
            win.isHidden = true
            windows.removeValue(forKey: key)
        }

        // Update or create per scene
        for scene in scenes {
            let key = ObjectIdentifier(scene)
            if visible {
                if windows[key] == nil {
                    let window = UIWindow(windowScene: scene)
                    window.frame = scene.screen.bounds
                    window.windowLevel = .alert + 1 // ensure above sheets
                    let host = UIHostingController(rootView: PrivacyShieldView())
                    host.view.backgroundColor = .white // ensure opaque background
                    window.rootViewController = host
                    window.isOpaque = true
                    window.isUserInteractionEnabled = false
                    window.isHidden = false
                    windows[key] = window
                } else {
                    windows[key]?.frame = scene.screen.bounds
                    windows[key]?.isHidden = false
                }
            } else {
                windows[key]?.isHidden = true
            }
        }
    }
}
