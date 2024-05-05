//
//  IncomeResponse.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct IncomeRestModel: Codable {
    var id: String
    var userId: String
    var amount: Double
    var taxPaid: Double
    var creditedOn: String
    var currency: String
    var incomeType: String
    var incomeTag: String
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, amount, creditedOn, taxPaid, currency, incomeType, incomeTag
    }
    
    init(id: String = "", userId: String = "", amount: Double = 0.0, taxPaid: Double = 0.0, creditedOn: String = "", currency: String = "", incomeType: String = "", incomeTag: String = "") {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.taxPaid = taxPaid
        self.creditedOn = creditedOn
        self.currency = currency
        self.incomeType = incomeType
        self.incomeTag = incomeTag
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        amount = try container.decode(Double.self, forKey: .amount)
        taxPaid = try container.decode(Double.self, forKey: .taxPaid)
        creditedOn = try container.decode(String.self, forKey: .creditedOn)
        currency = try container.decode(String.self, forKey: .currency)
        incomeType = try container.decode(String.self, forKey: .incomeType)
        incomeTag = try container.decode(String.self, forKey: .incomeTag)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(!id.isEmpty) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(userId, forKey: .userId)
        try container.encode(amount, forKey: .amount)
        try container.encode(taxPaid, forKey: .taxPaid)
        try container.encode(creditedOn, forKey: .creditedOn)
        try container.encode(currency, forKey: .currency)
        try container.encode(incomeType, forKey: .incomeType)
        try container.encode(incomeTag, forKey: .incomeTag)
    }
}
