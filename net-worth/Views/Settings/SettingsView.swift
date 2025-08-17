import SwiftUI

struct SettingsView: View {
    @AppStorage("appAppearance") private var appAppearanceRaw: String = AppAppearance.system.rawValue
    private var appAppearance: AppAppearance { AppAppearance(rawValue: appAppearanceRaw) ?? .system }
    @State private var navCollapsed = false
    
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
            ScrollView {
                GeometryReader { proxy in
                    Color.clear.preference(key: NavBarOffsetKey.self, value: proxy.frame(in: .named("settingsScroll")).minY)
                }
                .frame(height: 0)
                VStack(spacing: 16) {
                    AppearanceCard(selection: appearanceBinding)
                    SecurityCard()
                }
                .padding(16)
            }
            .background(Color.canvasBackground.ignoresSafeArea())
            .coordinateSpace(name: "settingsScroll")
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { navCollapsed = y < -8 }
            }
        }
    }
}

struct AppearanceCard: View {
    @Binding var selection: AppAppearance
    @Namespace private var ns
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPEARANCE")
                .font(.caption).bold()
                .foregroundColor(.secondary)
                .tracking(0.8)
            AppearancePreview(selection: selection)
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
                        .foregroundColor(selection == mode ? .white : .primary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 78)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.subtleSeparator)
                                if selection == mode {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(LinearGradient.airbnbAccent)
                                        .matchedGeometryEffect(id: "appearanceSel", in: ns)
                                }
                            }
                        )
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
        )
        .elevatedShadow()
    }
}

struct AppearancePreview: View {
    let selection: AppAppearance
    private var scheme: ColorScheme? {
        switch selection {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.elevatedBackground)
            VStack(spacing: 10) {
                // Simulated nav bar
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient.airbnbAccent)
                    .frame(height: 20)
                    .opacity(0.8)
                // Simulated content cards
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.subtleSeparator)
                        .frame(height: 28)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.subtleSeparator)
                        .frame(height: 28)
                }
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.subtleSeparator)
                    .frame(height: 28)
            }
            .padding(12)
        }
        .frame(height: 120)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
        )
        .preferredColorScheme(scheme)
    }
}

struct SecurityCard: View {
    @AppStorage("biometricLockEnabled") private var biometricEnabled: Bool = false
    @AppStorage("allowPasscodeFallback") private var allowPasscodeFallback: Bool = true
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SECURITY")
                .font(.caption).bold()
                .foregroundColor(.secondary)
                .tracking(0.8)
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "faceid").font(.title3.weight(.semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Face ID").font(.subheadline).bold()
                    Text("Require Face ID when reopening the app.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $biometricEnabled)
                    .labelsHidden()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.subtleSeparator)
            )
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "key").font(.title3.weight(.semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Passcode fallback").font(.subheadline).bold()
                    Text("Use device passcode if biometrics are unavailable.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $allowPasscodeFallback)
                    .labelsHidden()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.subtleSeparator)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.subtleSeparator, lineWidth: 1)
        )
        .elevatedShadow()
    }
}
