import SwiftUI

// MARK: - Models
public struct AppBanner: Identifiable {
    public enum Style { case neutral, warning, error, success }
    public let id = UUID()
    public let icon: String
    public let title: String
    public let message: String?
    public let style: Style
    public let actionTitle: String?
    public let action: (() -> Void)?
    
    public init(icon: String, title: String, message: String? = nil, style: Style = .neutral, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.style = style
        self.actionTitle = actionTitle
        self.action = action
    }
}

public final class BannerCenter: ObservableObject {
    @Published public var banner: AppBanner? = nil
    public init() {}
    public func show(_ banner: AppBanner) { withAnimation(.easeInOut(duration: 0.2)) { self.banner = banner } }
    public func clear() { withAnimation(.easeInOut(duration: 0.2)) { self.banner = nil } }
    public func showTemporary(_ banner: AppBanner, duration: TimeInterval = 3.0) {
        show(banner)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            if self?.banner?.id == banner.id { self?.clear() }
        }
    }
}

// MARK: - Helpers
public extension BannerCenter {
    func showError(message: String, retryTitle: String? = nil, retry: (() -> Void)? = nil) {
        // Only treat as offline when the message explicitly indicates offline,
        // not for generic transport errors, timeouts, or connection lost.
        let isOffline = message.localizedCaseInsensitiveContains("offline") || message.localizedCaseInsensitiveContains("no internet")
        let title = isOffline ? "No internet connection" : "Something went wrong"
        let subtitle = isOffline ? "You're offline or the connection was lost." : nil
        show(
            AppBanner(
                icon: isOffline ? "wifi.exclamationmark" : "exclamationmark.triangle.fill",
                title: title,
                message: subtitle,
                style: isOffline ? .error : .warning,
                actionTitle: retryTitle,
                action: retry
            )
        )
    }
}

// MARK: - Views
public struct TopBannerView: View {
    let banner: AppBanner
    var onDismiss: (() -> Void)? = nil
    public init(banner: AppBanner, onDismiss: (() -> Void)? = nil) { self.banner = banner; self.onDismiss = onDismiss }
    private var accent: Color {
        switch banner.style {
        case .neutral: return .airbnbPrimary
        case .warning: return .yellow
        case .error: return .airbnbPrimary
        case .success: return .green
        }
    }
    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.12))
                Image(systemName: banner.icon)
                    .foregroundStyle(LinearGradient.airbnbAccent)
            }
            .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title).font(.subheadline).bold()
                if let message = banner.message, !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            HStack(spacing: 10) {
                if let actionTitle = banner.actionTitle, let action = banner.action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.borderless)
                    .tint(.secondary)
                }
                if let onDismiss {
                    Button(action: { withAnimation(.easeInOut(duration: 0.22)) { onDismiss() } }) {
                        Image(systemName: "xmark")
                            .font(.footnote.bold())
                    }
                    .buttonStyle(.borderless)
                    .tint(.secondary)
                    .accessibilityLabel("Dismiss banner")
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Rectangle()
                .fill(Color.elevatedBackground)
                .overlay(
                    LinearGradient(colors: [accent.opacity(0.06), .clear], startPoint: .leading, endPoint: .trailing)
                )
        )
        .overlay(alignment: .bottom) { Rectangle().fill(Color.subtleSeparator).frame(height: 0.5) }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

public struct GlobalBannerHost: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var banners: BannerCenter
    @State private var hideOffline: Bool = false
    public init() {}
    public var body: some View {
        Group {
            if !networkMonitor.isConnected && !hideOffline {
                TopBannerView(
                    banner: AppBanner(icon: "wifi.exclamationmark", title: "No internet connection", message: "You're offline or the connection was lost.", style: .error),
                    onDismiss: { hideOffline = true }
                )
            } else if let b = banners.banner {
                TopBannerView(banner: b, onDismiss: { banners.clear() })
            }
        }
        .animation(.easeInOut(duration: 0.22), value: networkMonitor.isConnected)
        .animation(.easeInOut(duration: 0.22), value: hideOffline)
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected { hideOffline = false }
        }
    }
}
