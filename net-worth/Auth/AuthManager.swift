import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

enum AuthIntegrationError: LocalizedError {
    case notConfigured
    case noRootViewController
    case googleSignInFailed
    case missingIDToken

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Firebase/Google Sign-In is not configured. Add Firebase SDK and GoogleService-Info.plist."
        case .noRootViewController: return "Unable to find a root view controller to present Google Sign-In."
        case .googleSignInFailed: return "Google Sign-In failed. Please try again."
        case .missingIDToken: return "Missing ID token from Google Sign-In."
        }
    }
}

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private init() {}

    var isAvailable: Bool {
        #if canImport(FirebaseCore)
        return true
        #else
        return false
        #endif
    }

    func signInWithGoogle() async throws -> String {
        #if canImport(FirebaseCore) && canImport(GoogleSignIn) && canImport(FirebaseAuth)
        // Ensure Firebase is configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        #if canImport(UIKit)
        guard let presenting = Self.topViewController() else { throw AuthIntegrationError.noRootViewController }
        #else
        throw AuthIntegrationError.noRootViewController
        #endif

        // Use the modern signIn API if available
        if #available(iOS 13.0, *) {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
            guard let idToken = result.user.idToken?.tokenString else { throw AuthIntegrationError.missingIDToken }
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            let authResult = try await Self.firebaseSignIn(with: credential)
            return authResult.user.uid
        } else {
            throw AuthIntegrationError.googleSignInFailed
        }
        #else
        throw AuthIntegrationError.notConfigured
        #endif
    }

    // MARK: - Helpers
    #if canImport(FirebaseAuth)
    private static func firebaseSignIn(with credential: AuthCredential) async throws -> AuthDataResult {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: AuthIntegrationError.googleSignInFailed)
                }
            }
        }
    }
    #endif

    #if canImport(UIKit)
    @MainActor
    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }
    #endif
}
