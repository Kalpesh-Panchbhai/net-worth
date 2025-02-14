//
//  BalanceAccount.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/05/24.
//

import Foundation

struct AccountValue : Codable, Hashable {
    
    var currentBalance: BalanceAccountDetail = BalanceAccountDetail()
    
    var previousBalance: BalanceAccountDetail = BalanceAccountDetail()
    
}
