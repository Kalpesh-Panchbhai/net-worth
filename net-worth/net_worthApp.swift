//
//  net_worthApp.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/11/22.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct net_worthApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("signIn") var isSignIn = false
    @AppStorage("onboardingCompleted") var onboardingCompleted = false
    
    var body: some Scene {
        WindowGroup {
            if !isSignIn {
                LoginScreen()
                if !onboardingCompleted && isSignIn {
                    OnboardingView()
                }
            } else if !onboardingCompleted && isSignIn {
                OnboardingView()
            } else if onboardingCompleted && isSignIn {
                AuthenticationView()
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        UINavigationBar.appearance().barTintColor = UIColor(Color.theme.background)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(Color.theme.primaryText)]
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.stackedLayoutAppearance.normal.badgeBackgroundColor = UIColor(red: 0.3490196078, green: 0.7411764706, blue: 0.9568627451, alpha: 1)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        
        UIRefreshControl.appearance().tintColor = UIColor(Color.theme.primaryText)
        UIRefreshControl.appearance().attributedTitle = NSAttributedString(string: "Refreshing...", attributes: [NSAttributedString.Key.foregroundColor: UIColor(Color.theme.primaryText)])
        return true
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if(response.actionIdentifier == "open") {
            print("Open")
        } else if(response.actionIdentifier == "cancel") {
            print("Cancel")
        }
    }
}
