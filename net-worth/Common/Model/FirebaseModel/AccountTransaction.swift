//
//  AccountTransaction.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation
import FirebaseFirestoreSwift

struct AccountTransaction: Codable, Hashable {
    
    var id: String?
    var timestamp: Date
    var balanceChange: Double
    var currentBalance: Double
    
    var paid: Bool = true
    
    init(id: String = "", timestamp: Date = Date(), balanceChange: Double = 0.0, currentBalance: Double = 0.0, paid: Bool = true) {
        self.id = id
        self.timestamp = timestamp
        self.balanceChange = balanceChange
        self.currentBalance = currentBalance
        self.paid = paid
    }
}
