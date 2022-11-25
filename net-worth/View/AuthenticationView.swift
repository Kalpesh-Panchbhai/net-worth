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
                    if unlocked {
                        MainScreenView()
                    }
                }
                .onAppear(perform: authenticate)
            }else {
                MainScreenView()
            }
        }
        .onAppear(perform: loadDataMutualFund)
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
    
    private func loadDataMutualFund() {
        print("Loading Mutual Fund data")
        let initialDataLoadedMutualFund = UserDefaults.standard.bool(forKey: "InitialDataLoadedMutualFund")
        if(!initialDataLoadedMutualFund) {
            print("Loading Initial Mutual Fund data")
            settingsController.updateMutualFundData()
            print("Loaded Initial Mutual Fund data")
            UserDefaults.standard.set(true, forKey: "InitialDataLoadedMutualFund")
        } else {
            let day = Calendar.current.component(.day, from: Date())
            if(day != UserDefaults.standard.integer(forKey: "DataUpdatedMutualFundLastDay")) {
                print("Updating Mutual Fund data")
                settingsController.updateMutualFundData()
                UserDefaults.standard.set(day, forKey: "DataUpdatedMutualFundLastDay")
                print("Updated Mutual Fund data")
            }
        }
        print("Loaded Mutual Fund data")
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
