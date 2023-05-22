//
//  AccountTransactionData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

struct AccountTransactionData: Codable {
    
    var timestamp: Date
    var balanceChange: Double
    var currentBalance: Double
    var paid: Bool
}
