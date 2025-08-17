import SwiftUI

@main
struct net_worthApp: App {
    
    var body: some Scene {
        WindowGroup {
            RootView(userId: 1)
                .tint(.airbnbPrimary)
        }
    }
}
