//
//  SettingsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var isAuthenticationRequired: Bool
    
    private var settingsController = SettingsController()
    private var notificationController = NotificationController()
    
    init() {
        isAuthenticationRequired = settingsController.isAuthenticationRequired()
    }
    
    var body: some View {
        NavigationView(){
            List{
                Toggle("Require Face ID", isOn: $isAuthenticationRequired)
                    .onChange(of: isAuthenticationRequired) { newValue in
                        settingsController.setAuthentication(newValue: newValue)
                    }
                NavigationLink(destination: {
                    NotificationsView()
                }, label: {
                    Label("Notifications", systemImage: "play.square")
                })
                
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                Text("Version " + appVersion!)
            }
            .navigationTitle("Settings")
            .listStyle(.inset)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
