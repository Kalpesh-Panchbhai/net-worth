//
//  IncomeResponse.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct IncomeRestModel: Codable {
    var id: String
    var amount: Double
    var taxPaid: Double
    var currency: String
    var incomeType: String
    var incomeTag: String
    var creditedOn: String
    var userId: String
    
    private enum CodingKeys: String, CodingKey {
        case id, amount, taxPaid, currency, incomeType, incomeTag, creditedOn, userId
    }
    
    init(id: String = "", amount: Double = 0.0, taxPaid: Double = 0.0, currency: String = "", incomeType: String = "", incomeTag: String = "", creditedOn: String = "", userId: String = "") {
        self.id = id
        self.amount = amount
        self.taxPaid = taxPaid
        self.currency = currency
        self.incomeType = incomeType
        self.incomeTag = incomeTag
        self.creditedOn = creditedOn
        self.userId = userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        amount = try container.decode(Double.self, forKey: .amount)
        taxPaid = try container.decode(Double.self, forKey: .taxPaid)
        currency = try container.decode(String.self, forKey: .currency)
        incomeType = try container.decode(String.self, forKey: .incomeType)
        incomeTag = try container.decode(String.self, forKey: .incomeTag)
        creditedOn = try container.decode(String.self, forKey: .creditedOn)
        userId = try container.decode(String.self, forKey: .userId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(!id.isEmpty) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(amount, forKey: .amount)
        try container.encode(taxPaid, forKey: .taxPaid)
        try container.encode(currency, forKey: .currency)
        try container.encode(incomeType, forKey: .incomeType)
        try container.encode(incomeTag, forKey: .incomeTag)
        try container.encode(creditedOn, forKey: .creditedOn)
        try container.encode(userId, forKey: .userId)
    }
}
