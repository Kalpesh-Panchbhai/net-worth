//
//  AccountTransactionData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/12/23.
//

import Foundation

struct AccountTransactionData: Codable {
    
    var id: String
    var timestamp: Date
    var balanceChange: Double
    var currentBalance: Double
    var paid: Bool
}
