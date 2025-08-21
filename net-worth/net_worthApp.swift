import SwiftUI
import UIKit

@main
struct net_worthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var bannerCenter = BannerCenter()
    @StateObject private var tabCommands = TabCommandCenter()
    @StateObject private var lookupStore = LookupStore()
    @Environment(\.scenePhase) private var scenePhase
    init() {
        // Hide hairline at top (scroll edge large title), show after scrolling (standard)
        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithOpaqueBackground()
        scrollEdge.backgroundColor = UIColor.systemGroupedBackground
        scrollEdge.shadowColor = .clear
        
        let standard = UINavigationBarAppearance()
        standard.configureWithOpaqueBackground()
        standard.backgroundColor = UIColor.systemGroupedBackground
        // default shadowColor -> shows divider when scrolled
        
        let navBar = UINavigationBar.appearance()
        navBar.scrollEdgeAppearance = scrollEdge
        navBar.standardAppearance = standard
        navBar.compactAppearance = standard
    }
    var body: some Scene {
        WindowGroup {
            RootView(userId: 1)
                .environmentObject(networkMonitor)
                .environmentObject(bannerCenter)
                .environmentObject(tabCommands)
                .environmentObject(lookupStore)
                .tint(.airbnbPrimary)
                .task { await lookupStore.loadIfNeeded(userId: 1) }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Show a window-level privacy shield above all content (including sheets) when not active
            PrivacyShieldManager.shared.setVisible(newPhase != .active)
        }
    }
}
