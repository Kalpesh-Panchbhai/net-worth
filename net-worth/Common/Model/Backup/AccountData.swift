//
//  AccountData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

struct AccountData: Codable {
    
    var accountType: String
    var loanType: String
    var accountName: String
    var currentBalance: Double
    var paymentReminder: Bool
    var paymentDate: Int
    var currency: String
    var active: Bool
    
    var accountInBroker: [AccountInBrokerData]
    
    var accountTransaction: [AccountTransactionData]
    
}
