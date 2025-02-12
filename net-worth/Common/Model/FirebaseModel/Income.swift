//
//  Income.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/02/23.
//

import Foundation

class Income: Codable, Hashable, Equatable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Income, rhs: Income) -> Bool {
        return false
    }
    
    var id: Int
    var amount: Double
    var taxpaid: Double
    var creditedDate: Date
    var currency: String
    var type: Int
    var tag: Int
    
    init(id: Int = 0, amount: Double = 0.0, taxpaid: Double = 0.0, creditedDate: Date = Date.now, currency: String = "", type: Int = 0, tag: Int = 0) {
        self.id = id
        self.amount = amount
        self.taxpaid = taxpaid
        self.creditedDate = creditedDate
        self.currency = currency
        self.type = type
        self.tag = tag
    }
}
