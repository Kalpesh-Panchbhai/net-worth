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
    
    public func isAuthenticationRequired() -> Bool {
        return UserDefaults.standard.bool(forKey: "authentication")
    }
    
    public func getDefaultCurrency() -> Currency {
        if let data = UserDefaults.standard.data(forKey: "default_currency") {
            do {
                let decoder = JSONDecoder()

                let currency = try decoder.decode(Currency.self, from: data)

                return currency
            } catch {
                print("Unable to Decode Note (\(error))")
            }
        }
        
        return Currency()
    }
    
    public func setAuthentication(newValue: Bool) {
        UserDefaults.standard.set(newValue, forKey: "authentication")
    }
    
    public func setDefaultCurrency(newValue: Currency) {
        do {
            let encoder = JSONEncoder()

            let data = try encoder.encode(newValue)

            // Write/Set Data
            UserDefaults.standard.set(data, forKey: "default_currency")

        } catch {
            print("Unable to Encode Note (\(error))")
        }
    }
}
