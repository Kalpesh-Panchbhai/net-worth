//
//  IncomeResponse.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct IncomeRestModel: Codable {
    var id: Int
    var userId: Int
    var amount: Double
    var taxPaid: Double
    var creditedDate: String
    var currency: String
    var incomeType: Int
    var incomeTag: Int
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, amount, creditedDate, taxPaid, currency, incomeType, incomeTag
    }
    
    init(id: Int = 0, userId: Int = 0, amount: Double = 0.0, taxPaid: Double = 0.0, creditedDate: String = "", currency: String = "", incomeType: Int = 0, incomeTag: Int = 0) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.taxPaid = taxPaid
        self.creditedDate = creditedDate
        self.currency = currency
        self.incomeType = incomeType
        self.incomeTag = incomeTag
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        amount = try container.decode(Double.self, forKey: .amount)
        taxPaid = try container.decode(Double.self, forKey: .taxPaid)
        creditedDate = try container.decode(String.self, forKey: .creditedDate)
        currency = try container.decode(String.self, forKey: .currency)
        incomeType = try container.decode(Int.self, forKey: .incomeType)
        incomeTag = try container.decode(Int.self, forKey: .incomeTag)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(id != 0) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(userId, forKey: .userId)
        try container.encode(amount, forKey: .amount)
        try container.encode(taxPaid, forKey: .taxPaid)
        try container.encode(creditedDate, forKey: .creditedDate)
        try container.encode(currency, forKey: .currency)
        try container.encode(incomeType, forKey: .incomeType)
        try container.encode(incomeTag, forKey: .incomeTag)
    }
}
