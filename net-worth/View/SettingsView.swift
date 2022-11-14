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
    
    init() {
        isAuthenticationRequired = settingsController.isAuthenticationRequire()
    }
    
    var body: some View {
        NavigationView(){
            List{
                HStack {
                    Toggle("Require Face ID", isOn: $isAuthenticationRequired)
                        .onChange(of: isAuthenticationRequired) { _isOn in
                            settingsController.changeAuthentication(isRequired: _isOn)
                        }
                }
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
