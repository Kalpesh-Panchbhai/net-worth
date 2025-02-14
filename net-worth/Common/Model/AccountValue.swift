//
//  BalanceAccount.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/05/24.
//

import Foundation

struct AccountValue : Codable, Hashable {
    
    var currentBalance: Double = 0.0
    
    var previousBalance: Double = 0.0
    
}
