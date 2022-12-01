//
//  AccountModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 20/11/22.
//

import Foundation

class AccountModel {
    
    var sysId: UUID = UUID()
    
    var accountType: String = ""
    
    var accountName: String = ""
    
    var currentBalance: Double = 0.0
    
    var totalShares: Double = 0.0
    
    var paymentReminder: Bool = false
    
    var paymentDate: Int = 0
    
    var symbol: String = ""
}
