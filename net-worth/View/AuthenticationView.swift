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
    
    @State private var authenticateTypeMessage = ""
    
    private var settingsController = SettingsController()
    
    var body: some View {
        VStack {
            let authenticType = biometricType()
            if settingsController.isAuthenticationRequired() {
                if authenticType == .touch {
                    Button("Unlock with Touch ID") {
                        authenticateTypeMessage = "Unlock with Touch ID"
                        authenticate()
                    }.fullScreenCover(isPresented: $unlocked, content: {
                        MainScreenView()
                    })
                }else if authenticType == .face{
                    Button("Unlock with Face ID") {
                        authenticateTypeMessage = "Unlock with Face ID"
                        authenticate()
                    }.fullScreenCover(isPresented: $unlocked, content: {
                        MainScreenView()
                    })
                }
            }else {
                MainScreenView()
            }
        }
    }
    
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: authenticateTypeMessage) { success,
                authenticateError in
                if success {
                    unlocked = true
                }
            }
        }
    }
    
    private func biometricType() -> BiometricType {
        let authContext = LAContext()
        let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        if authContext.biometryType == .touchID {
            return .touch
        }else if authContext.biometryType == .faceID {
            return .face
        }else {
            return .none
        }
    }
    
    enum BiometricType {
        case touch
        case face
        case none
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
