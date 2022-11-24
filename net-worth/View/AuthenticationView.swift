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
        if settingsController.isAuthenticationRequired() {
            VStack {
                if unlocked {
                    MainScreenView()
                }
            }
            .onAppear(perform: authenticate)
        }else {
            MainScreenView()
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
