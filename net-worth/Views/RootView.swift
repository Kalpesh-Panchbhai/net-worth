import SwiftUI
import LocalAuthentication

struct RootView: View {
    let userId: Int
    @State private var selected: AppTab = .home
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    private var appAppearance: AppAppearance { AppAppearance(rawValue: appAppearanceRaw) ?? .system }
    private var colorSchemeOverride: ColorScheme? {
        switch appAppearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    @AppStorage("biometricLockEnabled") private var biometricEnabled: Bool = false
    @AppStorage("allowPasscodeFallback") private var allowPasscodeFallback: Bool = true
    @State private var isLocked: Bool = false
    @State private var authError: String? = nil
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .home:
                    PlaceholderScreen(title: AppTab.home.title, systemImage: AppTab.home.icon, tab: .home)
                case .accounts:
                    PlaceholderScreen(title: AppTab.accounts.title, systemImage: AppTab.accounts.icon, tab: .accounts)
                case .watchlist:
                    PlaceholderScreen(title: AppTab.watchlist.title, systemImage: AppTab.watchlist.icon, tab: .watchlist)
                case .income:
                    IncomeListView(userId: userId)
                case .settings:
                    SettingsView(userId: userId)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            AirbnbTabBar(selected: $selected, tabs: AppTab.allCases)
        }
        .safeAreaInset(edge: .top) {
            GlobalBannerHost()
        }
        .preferredColorScheme(colorSchemeOverride)
        .overlay {
            if biometricEnabled && isLocked {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "faceid").font(.system(size: 42, weight: .bold))
                        Text("Unlock with Face ID").font(.headline)
                        if let err = authError {
                            Text(err).font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal, 8)
                        }
                        Button(action: authenticate) {
                            HStack(spacing: 8) {
                                Image(systemName: "faceid")
                                Text("Unlock")
                                    .bold()
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule(style: .continuous).fill(LinearGradient.airbnbAccent)
                            )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.elevatedBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.subtleSeparator, lineWidth: 1)
                    )
                    .elevatedShadow()
                    .padding(24)
                }
            }
        }
        .onAppear {
            if biometricEnabled { isLocked = true; authenticate() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard biometricEnabled else { return }
            if newPhase == .active {
                if isLocked { authenticate() }
            } else if newPhase == .background {
                isLocked = true
            }
        }
        .onChange(of: biometricEnabled) { _, enabled in
            if enabled { isLocked = true; authenticate() } else { isLocked = false }
        }
    }

    private func authenticate() {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        var error: NSError?
        let reason = "Authenticate to continue"
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evalErr in
                DispatchQueue.main.async {
                    if success { self.isLocked = false; self.authError = nil; Haptics.success() }
                    else { self.authError = (evalErr as NSError?)?.localizedDescription ?? "Authentication failed" }
                }
            }
        } else if allowPasscodeFallback && context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evalErr in
                DispatchQueue.main.async {
                    if success { self.isLocked = false; self.authError = nil; Haptics.success() }
                    else { self.authError = (evalErr as NSError?)?.localizedDescription ?? "Authentication failed" }
                }
            }
        } else {
            self.authError = error?.localizedDescription ?? (allowPasscodeFallback ? "Biometrics not available" : "Biometrics not available and passcode is disabled")
        }
    }
}
