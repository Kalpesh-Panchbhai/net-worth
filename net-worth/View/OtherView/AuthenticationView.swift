//
//  AuthenticationView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI
import LocalAuthentication

struct AuthenticationView: View {
    
    @State private var unlocked =  false
    
    @State private var hasAlreadyLaunched =  false
    
    @State private var authenticateTypeMessage = "Please authenticate"
    
    private var settingsController = SettingsController()
    
    var body: some View {
        VStack {
            if settingsController.isAuthenticationRequired() {
                VStack {
                    Image(systemName: "lock.fill").font(.system(size: 30))
                    Text("Net Worth Locked").font(.system(.title).bold())
                    Text("Unlocked with Face ID to open Net Worth").font(.system(size: 14))
                    Button("Use Face ID", action: {
                        authenticate()
                    })
                    .foregroundColor(.blue)
                }
                .onAppear(perform: authenticate)
                .fullScreenCover(isPresented: $unlocked, content: {
                    MainScreenView()
                })
            }else {
                MainScreenView()
            }
        }
    }
    
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: authenticateTypeMessage) { success,
                authenticateError in
                if success {
                    unlocked = true
                }
            }
        }
    }

}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
