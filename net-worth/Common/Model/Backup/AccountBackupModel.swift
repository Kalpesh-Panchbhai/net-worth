//
//  AccountBackupModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

struct AccountBackupModel: Codable {
    
    var accountName: String
    var accountType: String
    var loanType: String
    var currency: String
    var active: Bool
    var balance: BalanceAccount
    
    var accountInBroker: [AccountInBrokerBackupModel]
    
}
