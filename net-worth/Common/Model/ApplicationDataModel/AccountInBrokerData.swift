//
//  AccountInBrokerData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/12/23.
//

import Foundation

struct AccountInBrokerData: Codable {
    
    var id: String
    var timestamp: Date
    var symbol: String
    var name: String
    var currentUnit: Double
    
    var accountTransactionData: [AccountTransactionData]
}
