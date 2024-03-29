//
//  Income.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/02/23.
//

import Foundation
import FirebaseFirestoreSwift

class Income: Codable, Hashable, Equatable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Income, rhs: Income) -> Bool {
        return false
    }
    
    var id: String?
    var amount: Double
    var taxpaid: Double
    var creditedOn: Date
    var currency: String
    var type: String
    var tag: String
    var createdDate: Date
    var deleted = false
    
    init(id: String? = nil, amount: Double = 0.0, taxpaid: Double = 0.0, creditedOn: Date = Date.now, currency: String = "", type: String = "", tag: String = "", createdDate: Date = Date.now, deleted: Bool = false) {
        self.id = id
        self.amount = amount
        self.taxpaid = taxpaid
        self.creditedOn = creditedOn
        self.currency = currency
        self.type = type
        self.tag = tag
        self.createdDate = createdDate
        self.deleted = deleted
    }
}
