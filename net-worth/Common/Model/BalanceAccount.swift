//
//  BalanceAccount.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/05/24.
//

import Foundation

struct BalanceAccount : Codable, Hashable {
    
    var currentDayValue: Double = 0.0
    
    var previousDayValue: Double = 0.0
    
}
