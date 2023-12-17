//
//  AccountInBrokerData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 17/12/23.
//

import Foundation

struct AccountInBrokerData: Codable {
    
    var timestamp: Date
    var symbol: String
    var name: String
    var currentUnit: Double
    
    var accountTransaction: [AccountTransactionData]
}
