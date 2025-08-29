import SwiftUI
import LocalAuthentication
import Security
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

struct SettingsView: View {
    let userId: Int
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    private var appAppearance: AppAppearance { AppAppearance(rawValue: appAppearanceRaw) ?? .system }
    @State private var navCollapsed = false
    @EnvironmentObject private var tabCommands: TabCommandCenter
    @EnvironmentObject private var lookupStore: LookupStore
    @EnvironmentObject private var banners: BannerCenter
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"
    @AppStorage("backendUserId") private var backendUserId: Int = -1

    private var appearanceBinding: Binding<AppAppearance> {
        Binding(
            get: { appAppearance },
            set: { newValue in
                appAppearanceRaw = newValue.rawValue
                Haptics.selection()
            }
        )
    }
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                GeometryReader { proxy in
                    Color.clear.preference(key: NavBarOffsetKey.self, value: proxy.frame(in: .named("settingsScroll")).minY)
                }
                .frame(height: 0)
                VStack(spacing: 16) {
                    AppearanceCard(selection: appearanceBinding)
                    PreferencesCard(userId: userId)
                    SecurityCard()
                    AccountManagementCard(userId: userId, onLogout: logoutAndWipe)
                }
                .padding(16)
                .padding(.bottom, LayoutConstants.tabBarHeight + 24)
                // Bottom anchor
                Color.clear.frame(height: LayoutConstants.tabBarHeight + 24).id("settingsBottom")
                }
                .background(ScrollToTopEnabler())
                .background(Color.canvasBackground.ignoresSafeArea())
                .coordinateSpace(name: "settingsScroll")
                .onChange(of: tabCommands.scrollToBottomRequest) { _, req in
                    guard req == .settings else { return }
                    withAnimation(.easeInOut(duration: 0.35)) { proxy.scrollTo("settingsBottom", anchor: .bottom) }
                    DispatchQueue.main.async { tabCommands.scrollToBottomRequest = nil }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 66) }
    }

    // MARK: - Logout implementation
    private func logoutAndWipe() {
        // 1) Sign out from auth providers
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
        #if canImport(FirebaseAuth)
        _ = try? Auth.auth().signOut()
        #endif

        // 2) Clear UserDefaults
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
            UserDefaults.standard.synchronize()
        }

        // 3) Reset in-memory stores
        lookupStore.reset()

        // 4) Route back to onboarding
        backendUserId = -1

        // 5) Feedback
        banners.showTemporary(AppBanner(icon: "checkmark.circle.fill", title: "Signed out", message: "Local data cleared.", style: .success))
    }
}
// MARK: - Account Management (Logout & Delete)
struct AccountManagementCard: View {
    let userId: Int
    @State private var showConfirm = false
    @State private var showConfirmDelete = false
    @State private var isDeleting = false
    var onLogout: () -> Void
    @AppStorage("backendUserId") private var backendUserId: Int = -1
    @AppStorage("biometricLockEnabled") private var biometricEnabled: Bool = false
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var lookupStore: LookupStore
    var body: some View {
        SettingsGroup(title: "Account") {
            VStack(spacing: 0) {
                // Sign out & local wipe
                Button(action: { showConfirm = true }) {
                    HStack {
                        ZStack {
                            Circle().fill(Color.red.opacity(0.12))
                            Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(.red)
                        }
                        .frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sign out & delete local data")
                                .font(.subheadline).bold()
                                .foregroundColor(.red)
                            Text("Removes all data from this device and returns to onboarding.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    "Sign out & delete local data?",
                    isPresented: $showConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Sign out & delete", role: .destructive) { onLogout() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will sign you out, clear preferences, and remove all locally stored data. This won't delete data on the server.")
                }

                // Divider between rows
                Rectangle().fill(Color.subtleSeparator)
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)

                // Delete account (server + local wipe)
                Button(action: { showConfirmDelete = true }) {
                    HStack {
                        ZStack {
                            Circle().fill(Color.red.opacity(0.12))
                            Image(systemName: "trash").foregroundColor(.red)
                        }
                        .frame(width: 32, height: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete account permanently")
                                .font(.subheadline).bold()
                                .foregroundColor(.red)
                            Text("Deletes your account and data from the server. This action cannot be undone.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(isDeleting)
                .confirmationDialog(
                    "Delete account permanently?",
                    isPresented: $showConfirmDelete,
                    titleVisibility: .visible
                ) {
                    Button("Delete account", role: .destructive) { Task { await deleteAccount() } }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete your account and server-side data. You cannot undo this.")
                }
            }
        }
    }

    @MainActor
    private func deleteAccount() async {
        guard !isDeleting else { return }
        // 1) Require Face ID/biometrics with device passcode fallback
        let authenticated = await authenticateForAccountDeletion()
        guard authenticated else {
            banners.showTemporary(AppBanner(icon: "exclamationmark.triangle.fill", title: "Authentication required", message: "Face ID or device passcode is required to delete your account.", style: .warning))
            return
        }

        isDeleting = true
        defer { isDeleting = false }
        do {
            try await RestClient().deleteUser(id: userId)
            // Sign out providers
            #if canImport(GoogleSignIn)
            GIDSignIn.sharedInstance.signOut()
            #endif
            #if canImport(FirebaseAuth)
            _ = try? Auth.auth().signOut()
            #endif
            // Clear all UserDefaults
            if let bundleId = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleId)
                UserDefaults.standard.synchronize()
            }
            // Reset in-memory stores
            lookupStore.reset()
            // Route back to onboarding
            backendUserId = -1
            banners.showTemporary(AppBanner(icon: "trash.circle.fill", title: "Account deleted", message: "Your account has been removed.", style: .success))
        } catch {
            let msg = (error as NSError).localizedDescription
            banners.showTemporary(AppBanner(icon: "exclamationmark.triangle.fill", title: "Delete failed", message: msg, style: .warning))
        }
    }

    /// Authenticate the user according to the app's security setting:
    /// - If Face ID is enabled and available: require Face ID first, then require device passcode.
    /// - If Face ID is disabled or unavailable: require device passcode only.
    private func authenticateForAccountDeletion() async -> Bool {
        let bioContext = LAContext()
        bioContext.localizedFallbackTitle = "Use Passcode"
        var bioError: NSError?

        let hasBiometrics = bioContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &bioError)

        if biometricEnabled && hasBiometrics {
            // Step 1: Biometric authentication (Face ID/Touch ID)
            let bioReason = "Confirm with Face ID to continue."
            let bioSuccess = await withCheckedContinuation { continuation in
                bioContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: bioReason) { success, _ in
                    continuation.resume(returning: success)
                }
            }
            guard bioSuccess else { return false }

            // Step 2: Device passcode only
            return await authenticateDevicePasscode(reason: "Enter device passcode to confirm deletion.")
        } else {
            // No biometrics enabled/available: require passcode only
            return await authenticateDevicePasscode(reason: "Enter device passcode to confirm deletion.")
        }
    }

    /// Presents a device passcode-only prompt using a temporary Keychain item protected
    /// with SecAccessControl(.devicePasscode). Returns true if the user successfully enters passcode.
    private func authenticateDevicePasscode(reason: String) async -> Bool {
        // Create an item requiring device passcode
        let tag = "networth.passcode.probe." + UUID().uuidString
        var sacError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .devicePasscode, &sacError) else {
            return false
        }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecAttrAccount as String: "auth",
            kSecAttrAccessControl as String: access,
            kSecValueData as String: Data("auth".utf8)
        ]
        // Add the item (ignore duplicates since tag is unique)
        SecItemAdd(addQuery as CFDictionary, nil)

        // Trigger passcode UI by reading it back with an operation prompt
        let laCtx = LAContext()
        laCtx.localizedFallbackTitle = ""
        laCtx.localizedReason = reason
        // Disable any possible authentication reuse window to force a fresh prompt
        laCtx.touchIDAuthenticationAllowableReuseDuration = 0
        let copyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecAttrAccount as String: "auth",
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: laCtx,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(copyQuery as CFDictionary, &result)

        // Cleanup the temporary item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        return status == errSecSuccess
    }
}

private extension PreferencesCard {
    func sfSymbolForCurrency(code: String) -> String? {
        let c = code.uppercased()
        switch c {
        case "USD", "CAD", "AUD", "NZD", "SGD", "HKD", "MXN", "ARS", "CLP": return "dollarsign.circle"
        case "EUR": return "eurosign.circle"
        case "GBP": return "sterlingsign.circle"
        case "JPY", "CNY": return "yensign.circle"
        case "INR": return "indianrupeesign.circle"
        case "KRW": return "wonsign.circle"
        case "RUB": return "rublesign.circle"
        case "TRY": return "turkishlirasign.circle"
        case "THB": return "bahtsign.circle"
        case "ILS": return "shekelsign.circle"
        default: return nil
        }
    }
}

struct DataCard: View {
    let userId: Int
    var body: some View {
        SettingsGroup(title: "Data") {
            VStack(spacing: 0) {
                NavigationLink {
                    IncomeTypesView(userId: userId)
                } label: {
                    SettingsCell(icon: "creditcard", title: "Income sources", subtitle: "View all income sources") {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
                Rectangle().fill(Color.subtleSeparator)
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)
                NavigationLink {
                    IncomeTagsView(userId: userId)
                } label: {
                    SettingsCell(icon: "tag", title: "Income tags", subtitle: "View all income tags") {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct PreferencesCard: View {
    let userId: Int
    @AppStorage("defaultCurrencyCode") private var code: String = "INR"
    @EnvironmentObject private var lookup: LookupStore
    var body: some View {
        SettingsGroup(title: "Preferences") {
            VStack(spacing: 0) {
                // Default currency
                NavigationLink { DefaultCurrencyView() } label: {
                    let selected = CurrencyCatalog.byCode[code.uppercased()]
                    SettingsCell(
                        title: "Default currency",
                        subtitle: selected?.name ?? code.uppercased(),
                        leading: {
                            ZStack {
                                Circle().fill(Color.airbnbPrimary.opacity(0.12))
                                if let icon = sfSymbolForCurrency(code: code) {
                                    Image(systemName: icon)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.airbnbPrimary)
                                } else {
                                    Text((selected?.symbol ?? code))
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.airbnbPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.3)
                                        .allowsTightening(true)
                                        .frame(width: 20, height: 20, alignment: .center)
                                }
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        }
                    ) {
                        HStack(spacing: 6) {
                            Text(selected?.symbol ?? code)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Rectangle().fill(Color.subtleSeparator)
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)
                // Income sources
                NavigationLink { IncomeTypesView(userId: userId) } label: {
                    SettingsCell(
                        title: "Income sources",
                        subtitle: lookup.incomeSources.first(where: { $0.isDefault })?.name ?? "Not set",
                        leading: {
                            ZStack {
                                Circle().fill(Color.airbnbPrimary.opacity(0.12))
                                Image(systemName: "creditcard")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.airbnbPrimary)
                            }
                            .frame(width: 32, height: 32)
                        }
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
                Rectangle().fill(Color.subtleSeparator)
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)
                // Income tags
                NavigationLink { IncomeTagsView(userId: userId) } label: {
                    SettingsCell(
                        title: "Income tags",
                        subtitle: lookup.incomeTags.first(where: { $0.isDefault })?.name ?? "Not set",
                        leading: {
                            ZStack {
                                Circle().fill(Color.airbnbPrimary.opacity(0.12))
                                Image(systemName: "tag")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.airbnbPrimary)
                            }
                            .frame(width: 32, height: 32)
                        }
                    ) {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Reusable Settings Components
struct SettingsGroup<Content: View>: View {
    let title: String?
    let showHeader: Bool
    let footer: String?
    let content: Content
    init(title: String? = nil, showHeader: Bool = true, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.showHeader = showHeader
        self.footer = footer
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 12) {
                if showHeader, let title {
                    Text(title.uppercased())
                        .font(.caption).bold()
                        .foregroundColor(.secondary)
                        .tracking(0.8)
                }
                content
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.elevatedBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .elevatedShadow()
            if let footer, !footer.isEmpty {
                Text(footer)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                    .padding(.top, 2)
            }
        }
    }
}

struct SettingsCell<Trailing: View>: View {
    let icon: String?
    let title: String
    let subtitle: String?
    let trailing: Trailing
    private let customLeading: AnyView?
    init(icon: String, title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
        self.customLeading = nil
    }
    init(title: String, subtitle: String? = nil, @ViewBuilder leading: () -> some View, @ViewBuilder trailing: () -> Trailing) {
        self.icon = nil
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
        self.customLeading = AnyView(leading())
    }
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let customLeading {
                customLeading
            } else {
                ZStack {
                    Circle().fill(Color.airbnbPrimary.opacity(0.12))
                    if let icon { Image(systemName: icon).foregroundColor(.airbnbPrimary) }
                }
                .frame(width: 32, height: 32)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).bold()
                    .foregroundColor(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            Spacer()
            trailing
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

struct AppearanceCard: View {
    @Binding var selection: AppAppearance
    @Namespace private var ns
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        SettingsGroup(title: "Appearance") {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    ForEach(AppAppearance.allCases) { mode in
                        Button {
                            withAnimation(.snappy) { selection = mode }
                            Haptics.selection()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: mode.icon)
                                    .font(.title3.weight(.semibold))
                                Text(mode.title)
                                    .font(.footnote.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(
                                selection == mode ? .white : (colorScheme == .dark ? Color.white.opacity(0.92) : .primary)
                            )
                            .padding(.vertical, 10)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(
                                ZStack {
                                    if selection == mode {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(LinearGradient.airbnbAccent)
                                            .matchedGeometryEffect(id: "appearanceSel", in: ns)
                                            .modifier(ElevatedShadow(radiusLight: 8, yLight: 4, radiusDark: 6, yDark: 3))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(colorScheme == .dark ? Color(red: 58/255, green: 58/255, blue: 63/255) : Color.elevatedBackground)
                                            .modifier(ElevatedShadow(radiusLight: 8, yLight: 4, radiusDark: 6, yDark: 3))
                                    }
                                }
                            )
                            // Soft top highlight only for selected chip in dark mode
                            .overlay(alignment: .top) {
                                if colorScheme == .dark && selection == mode {
                                    LinearGradient(colors: [Color.white.opacity(0.10), .clear], startPoint: .top, endPoint: .bottom)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                            .overlay(alignment: .topTrailing) {
                                if selection == mode {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(6)
                                }
                            }
                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityLabel(Text("Appearance \(mode.title)"))
                    }
                }
            }
        }
    }
}

struct SecurityCard: View {
    @AppStorage("biometricLockEnabled") private var biometricEnabled: Bool = false
    @AppStorage("allowPasscodeFallback") private var allowPasscodeFallback: Bool = true
    @EnvironmentObject private var banners: BannerCenter
    @State private var faceIDToggle: Bool = false

    private var biometricBinding: Binding<Bool> {
        Binding(
            get: { faceIDToggle },
            set: { newValue in
                if newValue {
                    // Enable directly
                    faceIDToggle = true
                    biometricEnabled = true
                    Haptics.selection()
                } else {
                    // Keep UI ON until user authenticates to disable
                    faceIDToggle = true
                    confirmDisableFaceID()
                }
            }
        )
    }
    var body: some View {
        SettingsGroup(title: "Security") {
            VStack(spacing: 0) {
                SettingsCell(icon: "faceid", title: "Face ID", subtitle: "Require Face ID when reopening the app.") {
                    Toggle("", isOn: biometricBinding)
                        .labelsHidden()
                        .tint(.airbnbPrimary)
                }
                Rectangle().fill(Color.subtleSeparator)
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)
                SettingsCell(icon: "key", title: "Passcode fallback", subtitle: "Use device passcode if biometrics are unavailable.") {
                    Toggle("", isOn: $allowPasscodeFallback)
                        .labelsHidden()
                        .tint(.airbnbPrimary)
                }
            }
            .onAppear { faceIDToggle = biometricEnabled }
            .onChange(of: biometricEnabled) { _, newVal in faceIDToggle = newVal }
        }
    }
    private func confirmDisableFaceID() {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        var error: NSError?
        let reason = "Authenticate to disable Face ID lock"
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evalErr in
                DispatchQueue.main.async {
                    if success {
                        self.faceIDToggle = false
                        self.biometricEnabled = false
                        Haptics.selection()
                    } else {
                        self.faceIDToggle = true
                        self.banners.showTemporary(AppBanner(icon: "exclamationmark.triangle.fill", title: "Authentication required", message: (evalErr as NSError?)?.localizedDescription ?? "Face ID authentication failed", style: .warning))
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.faceIDToggle = true
                self.banners.showTemporary(AppBanner(icon: "faceid", title: "Face ID not available", message: error?.localizedDescription, style: .warning))
            }
        }
    }
}
