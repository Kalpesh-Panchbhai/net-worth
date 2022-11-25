//
//  SetingsController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import Foundation
import CoreData
import SwiftUI

class SettingsController {
    
    private var mutualFundController = MutualFundController()
    
    public func isAuthenticationRequired() -> Bool {
        return UserDefaults.standard.bool(forKey: "authentication")
    }
    
    public func setAuthentication(newValue: Bool) {
        UserDefaults.standard.set(newValue, forKey: "authentication")
    }
    
    public func updateMutualFundData() {
        mutualFundController.fetch()
    }
    
}
