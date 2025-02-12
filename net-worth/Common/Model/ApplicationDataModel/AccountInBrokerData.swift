//
//  AccountInBrokerData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/12/23.
//

import Foundation

struct AccountInBrokerData: Codable {
    
    var accountInBroker: AccountInBroker
    
    var accountTransaction: [AccountTransaction]
}
