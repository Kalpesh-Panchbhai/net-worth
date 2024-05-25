//
//  AccountInBrokerBackupModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 17/12/23.
//

import Foundation

struct AccountInBrokerBackupModel: Codable {
    
    var id: String
    var accountId: String
    var symbol: String
    var name: String
    var currentUnit: Double
    var balance: BalanceAccount
}
