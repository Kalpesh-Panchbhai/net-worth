import UIKit
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        #endif
        #if canImport(GoogleSignIn)
        // Configure Google Sign-In
        var resolvedClientID: String? = nil
        #if canImport(FirebaseCore)
        resolvedClientID = FirebaseApp.app()?.options.clientID
        #endif
        if resolvedClientID == nil {
            // Try Info.plist -> GIDClientID
            if let infoClient = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String, !infoClient.isEmpty {
                resolvedClientID = infoClient
            }
        }
        if resolvedClientID == nil {
            // Try GoogleService-Info.plist -> CLIENT_ID
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path),
               let gsClient = dict["CLIENT_ID"] as? String, !gsClient.isEmpty {
                resolvedClientID = gsClient
            }
        }
        if let clientID = resolvedClientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        #endif
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Show shield ASAP before app switcher snapshot
        PrivacyShieldManager.shared.setVisible(true)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        PrivacyShieldManager.shared.setVisible(false)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        #if canImport(GoogleSignIn)
        if GIDSignIn.sharedInstance.handle(url) { return true }
        #endif
        return false
    }
}
