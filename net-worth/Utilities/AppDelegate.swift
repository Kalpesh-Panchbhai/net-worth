import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationWillResignActive(_ application: UIApplication) {
        // Show shield ASAP before app switcher snapshot
        PrivacyShieldManager.shared.setVisible(true)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        PrivacyShieldManager.shared.setVisible(false)
    }
}
