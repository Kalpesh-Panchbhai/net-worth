import SwiftUI
import UIKit

@main
struct net_worthApp: App {
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var bannerCenter = BannerCenter()
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
                .tint(.airbnbPrimary)
        }
    }
}
