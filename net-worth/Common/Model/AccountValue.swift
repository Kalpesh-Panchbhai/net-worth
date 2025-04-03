//
//  BalanceAccount.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/05/24.
//

import Foundation

struct AccountValue : Codable, Hashable {
    
    var currentValue: Double = 0.0
    
    var previousValue: Double = 0.0
    
    var invested: Double = 0.0
    
}
