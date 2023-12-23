//
//  AccountData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/12/23.
//

import Foundation

struct AccountData: Codable {
    
    var id: String
    var accountType: String
    var loanType: String
    var accountName: String
    var currentBalance: Double
    var paymentReminder: Bool
    var paymentDate: Int
    var currency: String
    var active: Bool
    var lastUpdated: Date
    
    var accountInBrokerData: [AccountInBrokerData]
    
    var accountTransactionData: [AccountTransactionData]
}
