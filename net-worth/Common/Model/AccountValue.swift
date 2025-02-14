//
//  BalanceAccount.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/05/24.
//

import Foundation

struct AccountValue : Codable, Hashable {
    
    var currentDayValue: BalanceAccountDetail = BalanceAccountDetail()
    
    var previousDayValue: BalanceAccountDetail = BalanceAccountDetail()
    
}
