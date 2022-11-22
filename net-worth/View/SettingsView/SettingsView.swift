//
//  SettingsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var isAuthenticationRequired: Bool
    @State private var isNotificationEnabled: Bool
    
    private var settingsController = SettingsController()
    private var notificationController = NotificationController()
    
    private var mutualFundController = MutualFundController()
    
    init() {
        isAuthenticationRequired = settingsController.isAuthenticationRequire()
        Thread.sleep(forTimeInterval: 1)
        isNotificationEnabled = notificationController.getGranted()
    }
    
    var body: some View {
        NavigationView(){
            List{
                Toggle("Require Face ID", isOn: $isAuthenticationRequired)
                    .onChange(of: isAuthenticationRequired) { _isOn in
                        settingsController.changeAuthentication(isRequired: _isOn)
                    }
                Toggle("Enable Notification", isOn: $isNotificationEnabled)
                
                Button("Update Mutual Fund Data", action: {
                    mutualFundController.schedule()
                })
                
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                Text("Version " + appVersion!)
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
