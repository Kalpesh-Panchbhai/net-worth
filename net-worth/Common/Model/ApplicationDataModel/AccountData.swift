//
//  AccountData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/12/23.
//

import Foundation

struct AccountData: Codable {
    
    var account: AccountRestModel
    
    var accountInBroker: [AccountInBrokerData]
    
    var accountTransaction: [AccountTransactionRestModel]
}
