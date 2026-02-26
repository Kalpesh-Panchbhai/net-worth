import LocalAuthentication
import Security
import SwiftUI

#if canImport(GoogleSignIn)
    import GoogleSignIn
#endif
#if canImport(FirebaseAuth)
    import FirebaseAuth
#endif

struct SettingsView: View {
    let userId: Int
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system
        .rawValue
    private var appAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
    }
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
                        Color.clear.preference(
                            key: NavBarOffsetKey.self,
                            value: proxy.frame(in: .named("settingsScroll")).minY)
                    }
                    .frame(height: 0)
                    VStack(spacing: 16) {
                        AccountProfileCard()
                        AppearanceCard(selection: appearanceBinding)
                        PreferencesCard(userId: userId)
                        DataRefreshCard()
                        SecurityCard()
                        BuildInfoCard()
                        AccountManagementCard(userId: userId, onLogout: logoutAndWipe)
                    }
                    .padding(16)
                    .padding(.bottom, LayoutConstants.tabBarHeight + 24)
                    // Bottom anchor
                    Color.clear.frame(height: LayoutConstants.tabBarHeight + 24).id(
                        "settingsBottom")
                }
                .background(ScrollToTopEnabler())
                .background(Color.canvasBackground.ignoresSafeArea())
                .coordinateSpace(name: "settingsScroll")
                .onChange(of: tabCommands.scrollToBottomRequest) { _, req in
                    guard req == .settings else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo("settingsBottom", anchor: .bottom)
                    }
                    DispatchQueue.main.async { tabCommands.scrollToBottomRequest = nil }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 66) }
    }

    // MARK: - Google Account Profile Card
    struct AccountProfileCard: View {
        @Environment(\.openURL) private var openURL
        @State private var name: String = ""
        @State private var email: String = ""
        @State private var photoURL: URL? = nil
        @State private var isSignedIn: Bool = false

        var body: some View {
            SettingsGroup(title: "Your profile") {
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.airbnbAccent)
                                .opacity(0.18)
                            if let url = photoURL {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView().scaleEffect(0.8)
                                    case .success(let img):
                                        img.resizable().scaledToFill()
                                    case .failure:
                                        placeholderInitials
                                    @unknown default:
                                        placeholderInitials
                                    }
                                }
                            } else {
                                placeholderInitials
                            }
                        }
                        .frame(width: 58, height: 58)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(LinearGradient.airbnbAccent, lineWidth: 2)
                                .opacity(0.7)
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName)
                                .font(.headline)
                            Text(displayEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Haptics.selection()
                        if let url = URL(string: "https://myaccount.google.com/") { openURL(url) }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(LinearGradient.airbnbAccent)
                        Text("Manage your Google Account")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            Haptics.selection()
                            if let url = URL(string: "https://myaccount.google.com/") {
                                openURL(url)
                            }
                        } label: {
                            Text("Open")
                                .font(.footnote.weight(.semibold))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Capsule().fill(LinearGradient.airbnbAccent))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    .padding(.top, 2)
                }
                .onAppear(perform: fetchIdentity)
            }
        }

        private var placeholderInitials: some View {
            Text(initials(from: displayName))
                .font(.headline.weight(.bold))
                .foregroundColor(.airbnbPrimary)
                .minimumScaleFactor(0.5)
        }

        private var displayName: String { name.isEmpty ? "Signed in" : name }
        private var displayEmail: String { email.isEmpty ? "Google account" : email }

        private func initials(from name: String) -> String {
            let comps = name.split(separator: " ")
            let first = comps.first?.prefix(1) ?? "N"
            let second = comps.dropFirst().first?.prefix(1) ?? "A"
            return String(first + second)
        }

        private func fetchIdentity() {
            #if canImport(GoogleSignIn)
                if let user = GIDSignIn.sharedInstance.currentUser {
                    isSignedIn = true
                    name = user.profile?.name ?? name
                    email = user.profile?.email ?? email
                    if let imageURL = user.profile?.imageURL(withDimension: 160) {
                        photoURL = imageURL
                    }
                    return
                }
            #endif
            #if canImport(FirebaseAuth)
                if let user = Auth.auth().currentUser {
                    isSignedIn = true
                    name = user.displayName ?? name
                    email = user.email ?? email
                    if let url = user.photoURL { photoURL = url }
                    return
                }
            #endif
            isSignedIn = false
        }
    }

    // MARK: - Build Info
    struct BuildInfoCard: View {
        @State private var expiration: Date? = nil
        @State private var buildInfo: (version: String, build: String, bundleId: String) = (
            "", "", ""
        )

        var body: some View {
            SettingsGroup(title: "Build") {
                VStack(spacing: 16) {
                    // App Version Row
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.airbnbPrimary.opacity(0.12))
                            Image(systemName: "app.badge")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.airbnbPrimary)
                        }
                        .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Version")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text("\(buildInfo.version) (\(buildInfo.build))")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)

                    // App Expiration Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color.airbnbPrimary.opacity(0.12))
                                Image(systemName: "clock")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.airbnbPrimary)
                            }
                            .frame(width: 32, height: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                let expDate = expiration ?? estimatedExpiration()
                                let text = timeRemainingText(until: expDate)
                                if text.lowercased().hasPrefix("expired") {
                                    Text(text)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.red)
                                } else {
                                    Text(text)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                }
                            }

                            Spacer()

                            let exp = expiration ?? estimatedExpiration()
                            Text(badgeText(for: exp))
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Capsule().fill(badgeColor(for: exp)))
                        }

                        // Date and time details
                        VStack(alignment: .leading, spacing: 4) {
                            let exp = expiration ?? estimatedExpiration()
                            Text(formattedDate(exp))
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            Text("at \(formattedTime(exp))")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 44)
                    }
                    .padding(.horizontal, 12)
                }
            }
            .onAppear(perform: loadBuildInfo)
        }

        private func formattedDate(_ date: Date) -> String {
            let df = DateFormatter()
            df.dateFormat = "EEEE, dd MMM yyyy"
            df.timeZone = TimeZone.current
            return df.string(from: date)
        }

        private func formattedTime(_ date: Date) -> String {
            let tf = DateFormatter()
            tf.dateFormat = "h:mm a"
            tf.timeZone = TimeZone.current
            return tf.string(from: date)
        }

        private func loadBuildInfo() {
            // Load build info
            buildInfo = MobileProvision.getBuildInfo()

            // Try to get actual expiration date, but don't worry if it fails
            if expiration == nil {
                if let mp = MobileProvision.read() {
                    self.expiration = mp.expirationDate
                }
            }
        }

        private func estimatedExpiration() -> Date {
            // Always provide a fallback expiration date based on build time + 7 days
            if let executablePath = Bundle.main.executablePath,
                let attributes = try? FileManager.default.attributesOfItem(atPath: executablePath),
                let creationDate = attributes[.creationDate] as? Date
            {
                return Calendar.current.date(byAdding: .day, value: 7, to: creationDate) ?? Date()
            }

            // Ultimate fallback: 7 days from now
            return Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        }

        private func daysRemaining(until date: Date) -> Int {
            let seconds = date.timeIntervalSinceNow
            let daysDouble = seconds / 86400.0
            if seconds >= 0 {
                // For future dates, count only fully remaining days (no rounding up)
                return Int(floor(daysDouble))
            } else {
                // For past dates, if less than a full day has passed, show 0 days
                // Otherwise, return negative full days elapsed
                let daysPast = Int(floor(abs(daysDouble)))
                return daysPast == 0 ? 0 : -daysPast
            }
        }

        private func timeRemainingText(until date: Date) -> String {
            let seconds = date.timeIntervalSinceNow
            if seconds <= 0 {
                // Already expired
                let days = abs(daysRemaining(until: date))
                if days >= 1 {
                    return "Expired \(days) day\(days == 1 ? "" : "s") ago"
                } else {
                    return "Expired"
                }
            }
            if seconds >= 86400 {
                let days = Int(floor(seconds / 86400))
                return "Expires in \(days) day\(days == 1 ? "" : "s")"
            } else if seconds >= 3600 {
                let hours = Int(floor(seconds / 3600))
                return "Expires in \(hours) hr\(hours == 1 ? "" : "s")"
            } else {
                // Less than an hour: show minutes, round up to at least 1 min
                let mins = max(1, Int(ceil(seconds / 60)))
                return "Expires in \(mins) min\(mins == 1 ? "" : "s")"
            }
        }

        private func badgeText(for date: Date) -> String {
            let d = daysRemaining(until: date)
            if d >= 0 { return "\(d)d left" } else { return "Expired" }
        }

        private func badgeColor(for date: Date) -> Color {
            let d = daysRemaining(until: date)
            if d < 0 { return .red }
            if d <= 2 { return .red }
            if d <= 5 { return .orange }
            return .green
        }
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
        banners.showTemporary(
            AppBanner(
                icon: "checkmark.circle.fill", title: "Signed out", message: "Local data cleared.",
                style: .success))
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
                            Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(
                                .red)
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
                    Text(
                        "This will sign you out, clear preferences, and remove all locally stored data. This won't delete data on the server."
                    )
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
                            Text(
                                "Deletes your account and data from the server. This action cannot be undone."
                            )
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
                    Text(
                        "This will permanently delete your account and server-side data. You cannot undo this."
                    )
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
            banners.showTemporary(
                AppBanner(
                    icon: "exclamationmark.triangle.fill", title: "Authentication required",
                    message: "Face ID or device passcode is required to delete your account.",
                    style: .warning))
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
            banners.showTemporary(
                AppBanner(
                    icon: "trash.circle.fill", title: "Account deleted",
                    message: "Your account has been removed.", style: .success))
        } catch {
            let msg = (error as NSError).localizedDescription
            banners.showTemporary(
                AppBanner(
                    icon: "exclamationmark.triangle.fill", title: "Delete failed", message: msg,
                    style: .warning))
        }
    }

    /// Authenticate the user according to the app's security setting:
    /// - If Face ID is enabled and available: require Face ID first, then require device passcode.
    /// - If Face ID is disabled or unavailable: require device passcode only.
    private func authenticateForAccountDeletion() async -> Bool {
        let bioContext = LAContext()
        bioContext.localizedFallbackTitle = "Use Passcode"
        var bioError: NSError?

        let hasBiometrics = bioContext.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &bioError)

        if biometricEnabled && hasBiometrics {
            // Step 1: Biometric authentication (Face ID/Touch ID)
            let bioReason = "Confirm with Face ID to continue."
            let bioSuccess = await withCheckedContinuation { continuation in
                bioContext.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics, localizedReason: bioReason
                ) { success, _ in
                    continuation.resume(returning: success)
                }
            }
            guard bioSuccess else { return false }

            // Step 2: Device passcode only
            return await authenticateDevicePasscode(
                reason: "Enter device passcode to confirm deletion.")
        } else {
            // No biometrics enabled/available: require passcode only
            return await authenticateDevicePasscode(
                reason: "Enter device passcode to confirm deletion.")
        }
    }

    /// Presents a device passcode-only prompt using a temporary Keychain item protected
    /// with SecAccessControl(.devicePasscode). Returns true if the user successfully enters passcode.
    private func authenticateDevicePasscode(reason: String) async -> Bool {
        // Create an item requiring device passcode
        let tag = "networth.passcode.probe." + UUID().uuidString
        var sacError: Unmanaged<CFError>?
        guard
            let access = SecAccessControlCreateWithFlags(
                nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .devicePasscode, &sacError)
        else {
            return false
        }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecAttrAccount as String: "auth",
            kSecAttrAccessControl as String: access,
            kSecValueData as String: Data("auth".utf8),
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
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(copyQuery as CFDictionary, &result)

        // Cleanup the temporary item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        return status == errSecSuccess
    }
}

extension PreferencesCard {
    fileprivate func sfSymbolForCurrency(code: String) -> String? {
        let c = code.uppercased()
        switch c {
        case "USD", "CAD", "AUD", "NZD", "SGD", "HKD", "MXN", "ARS", "CLP":
            return "dollarsign.circle"
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
                    SettingsCell(
                        icon: "creditcard", title: "Income sources",
                        subtitle: "View all income sources"
                    ) {
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
                    SettingsCell(
                        icon: "tag", title: "Income tags", subtitle: "View all income tags"
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

struct DataRefreshCard: View {
    @EnvironmentObject private var refreshManager: RefreshManager
    @EnvironmentObject private var banners: BannerCenter
    private let estimatedDuration: Double = 15.0

    var body: some View {
        SettingsGroup(title: "Data") {
            VStack(spacing: 0) {
                Button(action: { Task { await refreshManager.triggerRefresh(banners: banners) } }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.airbnbPrimary.opacity(0.12))
                            if refreshManager.isRefreshing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.airbnbPrimary)
                            } else {
                                Image(systemName: "arrow.trianglehead.2.counterclockwise")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.airbnbPrimary)
                            }
                        }
                        .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Refresh data")
                                .font(.subheadline).bold()
                                .foregroundColor(.primary)
                            Text(
                                refreshManager.isRefreshing
                                    ? "Updating data…"
                                    : "Update account data in the database"
                            )
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        }
                        Spacer()
                        if !refreshManager.isRefreshing {
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(refreshManager.isRefreshing)

                if refreshManager.isRefreshing {
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.airbnbPrimary.opacity(0.12))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(LinearGradient.airbnbAccent)
                                    .frame(
                                        width: geo.size.width
                                            * min(
                                                refreshManager.elapsedSeconds / estimatedDuration,
                                                0.95)
                                    )
                                    .animation(
                                        .easeOut(duration: 0.4),
                                        value: refreshManager.elapsedSeconds)
                            }
                        }
                        .frame(height: 6)
                        .padding(.horizontal, 12)

                        Text(progressLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 12)
                    }
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: refreshManager.isRefreshing)
        }
    }

    private var progressLabel: String {
        let secs = Int(refreshManager.elapsedSeconds)
        if secs < 1 { return "Starting…" }
        return "~\(secs)s elapsed"
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
                NavigationLink {
                    DefaultCurrencyView()
                } label: {
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
                NavigationLink {
                    IncomeTypesView(userId: userId)
                } label: {
                    SettingsCell(
                        title: "Income sources",
                        subtitle: lookup.incomeSources.first(where: { $0.isDefault })?.name
                            ?? "Not set",
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
                NavigationLink {
                    IncomeTagsView(userId: userId)
                } label: {
                    SettingsCell(
                        title: "Income tags",
                        subtitle: lookup.incomeTags.first(where: { $0.isDefault })?.name
                            ?? "Not set",
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
    init(
        title: String? = nil, showHeader: Bool = true, footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
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
    init(
        icon: String, title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
        self.customLeading = nil
    }
    init(
        title: String, subtitle: String? = nil, @ViewBuilder leading: () -> some View,
        @ViewBuilder trailing: () -> Trailing
    ) {
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
                                selection == mode
                                    ? .white
                                    : (colorScheme == .dark ? Color.white.opacity(0.92) : .primary)
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
                                            .modifier(
                                                ElevatedShadow(
                                                    radiusLight: 8, yLight: 4, radiusDark: 6,
                                                    yDark: 3))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                colorScheme == .dark
                                                    ? Color(
                                                        red: 58 / 255, green: 58 / 255,
                                                        blue: 63 / 255) : Color.elevatedBackground
                                            )
                                            .modifier(
                                                ElevatedShadow(
                                                    radiusLight: 8, yLight: 4, radiusDark: 6,
                                                    yDark: 3))
                                    }
                                }
                            )
                            // Soft top highlight only for selected chip in dark mode
                            .overlay(alignment: .top) {
                                if colorScheme == .dark && selection == mode {
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.10), .clear],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                SettingsCell(
                    icon: "faceid", title: "Face ID",
                    subtitle: "Require Face ID when reopening the app."
                ) {
                    Toggle("", isOn: biometricBinding)
                        .labelsHidden()
                        .tint(.airbnbPrimary)
                }
                Rectangle().fill(Color.subtleSeparator)
                    .frame(height: 0.5)
                    .padding(.horizontal, 12)
                SettingsCell(
                    icon: "key", title: "Passcode fallback",
                    subtitle: "Use device passcode if biometrics are unavailable."
                ) {
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
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason
            ) { success, evalErr in
                DispatchQueue.main.async {
                    if success {
                        self.faceIDToggle = false
                        self.biometricEnabled = false
                        Haptics.selection()
                    } else {
                        self.faceIDToggle = true
                        self.banners.showTemporary(
                            AppBanner(
                                icon: "exclamationmark.triangle.fill",
                                title: "Authentication required",
                                message: (evalErr as NSError?)?.localizedDescription
                                    ?? "Face ID authentication failed", style: .warning))
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.faceIDToggle = true
                self.banners.showTemporary(
                    AppBanner(
                        icon: "faceid", title: "Face ID not available",
                        message: error?.localizedDescription, style: .warning))
            }
        }
    }
}
