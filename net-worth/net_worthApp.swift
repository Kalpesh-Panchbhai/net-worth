import SwiftUI
import UIKit

#if canImport(GoogleSignIn)
    import GoogleSignIn
#endif
#if canImport(FirebaseCore)
    import FirebaseCore
#endif
#if canImport(FirebaseAuth)
    import FirebaseAuth
#endif

@main
struct net_worthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var bannerCenter = BannerCenter()
    @StateObject private var tabCommands = TabCommandCenter()
    @StateObject private var lookupStore = LookupStore()
    @StateObject private var refreshManager = RefreshManager()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("backendUserId") private var backendUserId: Int = -1
    init() {
        // Simplified navigation bar configuration for better iOS version compatibility
        let navBar = UINavigationBar.appearance()
        navBar.prefersLargeTitles = true
        navBar.tintColor = UIColor.systemBlue

        // Use default appearances to avoid conflicts
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        navBar.standardAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.scrollEdgeAppearance = appearance

        // Setup expiry notifications
        ExpiryNotifier.shared.setupExpiryNotifications()
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if backendUserId > 0 {
                    RootView(userId: backendUserId)
                } else {
                    OnboardingScreen()
                }
            }
            .environmentObject(networkMonitor)
            .environmentObject(bannerCenter)
            .environmentObject(tabCommands)
            .environmentObject(lookupStore)
            .environmentObject(refreshManager)
            .tint(.airbnbPrimary)
            .task {
                if backendUserId > 0 {
                    await lookupStore.loadIfNeeded(userId: backendUserId)
                }
            }
            .onChange(of: backendUserId) { _, newId in
                if newId > 0 {
                    Task { await lookupStore.loadIfNeeded(userId: newId) }
                }
            }
            .onOpenURL { url in
                #if canImport(GoogleSignIn)
                    _ = GIDSignIn.sharedInstance.handle(url)
                #endif
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Show a window-level privacy shield above all content (including sheets) when not active
            PrivacyShieldManager.shared.setVisible(newPhase != .active)
            // Ensure notifications are scheduled when app returns to foreground
            if newPhase == .active {
                ExpiryNotifier.shared.setupExpiryNotifications()
            }
        }
    }
}

// MARK: - Inline Onboarding (Google Sign-In)
private struct OnboardingScreen: View {
    @State private var isSigningIn = false
    @State private var errorMessage: String? = nil
    @AppStorage("backendUserId") private var backendUserId: Int = -1
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var lookupStore: LookupStore
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = ""
    @State private var showCurrencyPicker = false
    @State private var pendingUserId: Int? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(LinearGradient.airbnbAccent)
                    Text("Welcome to Net Worth")
                        .font(.title2.weight(.bold))
                    Text("Sign in to sync your data across devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    Button(action: { Task { await signIn() } }) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                            Text(isSigningIn ? "Signing in..." : "Continue with Google")
                                .bold()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(LinearGradient.airbnbAccent))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(isSigningIn)

                    if let msg = errorMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                Text("By continuing, you agree to the Terms and Privacy Policy.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
            .navigationBarHidden(true)
            .overlay(alignment: .top) { GlobalBannerHost() }
        }
        .fullScreenCover(
            isPresented: $showCurrencyPicker,
            onDismiss: {
                // Proceed only after user has picked a currency
                let code = defaultCurrencyCode.trimmingCharacters(in: .whitespacesAndNewlines)
                if !code.isEmpty, let id = pendingUserId {
                    backendUserId = id
                    Haptics.success()
                    Task { await lookupStore.loadIfNeeded(userId: id) }
                    pendingUserId = nil
                }
            }
        ) {
            NavigationStack {
                DefaultCurrencyView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(Color.canvasBackground, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            }
            .interactiveDismissDisabled(true)
        }
    }

    @MainActor
    private func signIn() async {
        guard !isSigningIn else { return }
        errorMessage = nil
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            #if canImport(FirebaseCore) && canImport(GoogleSignIn) && canImport(FirebaseAuth)
                if FirebaseApp.app() == nil { FirebaseApp.configure() }
                guard let presenting = topViewController() else {
                    throw NSError(
                        domain: "Auth", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unable to present sign-in"])
                }
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
                guard let idToken = result.user.idToken?.tokenString else {
                    throw NSError(
                        domain: "Auth", code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Missing ID token"])
                }
                let accessToken = result.user.accessToken.tokenString
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken, accessToken: accessToken)
                let authResult = try await withCheckedThrowingContinuation {
                    (cont: CheckedContinuation<AuthDataResult, Error>) in
                    Auth.auth().signIn(with: credential) { res, err in
                        if let err = err {
                            cont.resume(throwing: err)
                        } else if let res = res {
                            cont.resume(returning: res)
                        } else {
                            cont.resume(
                                throwing: NSError(
                                    domain: "Auth", code: -3,
                                    userInfo: [NSLocalizedDescriptionKey: "Sign-in failed"]))
                        }
                    }
                }
                let firebaseUID = authResult.user.uid
                let id = try await RestClient().registerFirebaseUser(uid: firebaseUID)
                if id > 0 {
                    // If default currency is not set yet, force selection before proceeding
                    if defaultCurrencyCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        pendingUserId = id
                        showCurrencyPicker = true
                    } else {
                        backendUserId = id
                        Haptics.success()
                        await lookupStore.loadIfNeeded(userId: id)
                    }
                } else {
                    throw NSError(
                        domain: "API", code: -4,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Failed to create or fetch user. Please try again."
                        ])
                }
            #else
                throw NSError(
                    domain: "Auth", code: -10,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Firebase/Google Sign-In not configured. Add Firebase packages and GoogleService-Info.plist."
                    ])
            #endif
        } catch {
            errorMessage = (error as NSError).localizedDescription
            banners.showError(message: errorMessage ?? "")
        }
    }

    @MainActor
    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        if let base { return ascend(from: base) }
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            return nil
        }
        return ascend(from: root)
    }

    private func ascend(from root: UIViewController) -> UIViewController {
        if let nav = root as? UINavigationController, let vis = nav.visibleViewController {
            return ascend(from: vis)
        }
        if let tab = root as? UITabBarController, let sel = tab.selectedViewController {
            return ascend(from: sel)
        }
        if let presented = root.presentedViewController { return ascend(from: presented) }
        return root
    }
}
