//
//  AccountData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/12/23.
//

import Foundation

struct AccountData: Codable {
    
    var account: Account
    
    var accountInBroker: [AccountInBrokerData]
    
    var accountTransaction: [AccountTransaction]
}
