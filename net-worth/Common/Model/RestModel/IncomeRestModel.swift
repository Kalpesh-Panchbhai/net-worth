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
    var creditedDate: String
    var currency: String
    var incomeType: String
    var incomeTag: String
    
    var avgAmount: Double = 0.0
    var avgTaxPaid: Double = 0.0
    var cumulativeAmount: Double = 0.0
    var cumulativeTaxPaid: Double = 0.0
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, amount, creditedDate, taxPaid, currency, incomeType, incomeTag, avgAmount, avgTaxPaid, cumulativeAmount, cumulativeTaxPaid
    }
    
    init(id: String = "", userId: String = "", amount: Double = 0.0, taxPaid: Double = 0.0, creditedDate: String = "", currency: String = "", incomeType: String = "", incomeTag: String = "", avgAmount: Double = 0.0, avgTaxPaid: Double = 0.0, cumulativeAmount: Double = 0.0, cumulativeTaxPaid: Double = 0.0) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.taxPaid = taxPaid
        self.creditedDate = creditedDate
        self.currency = currency
        self.incomeType = incomeType
        self.incomeTag = incomeTag
        self.avgAmount = avgAmount
        self.avgTaxPaid = avgTaxPaid
        self.cumulativeAmount = cumulativeAmount
        self.cumulativeTaxPaid = cumulativeTaxPaid
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        amount = try container.decode(Double.self, forKey: .amount)
        taxPaid = try container.decode(Double.self, forKey: .taxPaid)
        creditedDate = try container.decode(String.self, forKey: .creditedDate)
        currency = try container.decode(String.self, forKey: .currency)
        incomeType = try container.decode(String.self, forKey: .incomeType)
        incomeTag = try container.decode(String.self, forKey: .incomeTag)
        avgAmount = try container.decode(Double.self, forKey: .avgAmount)
        avgTaxPaid = try container.decode(Double.self, forKey: .avgTaxPaid)
        cumulativeAmount = try container.decode(Double.self, forKey: .cumulativeAmount)
        cumulativeTaxPaid = try container.decode(Double.self, forKey: .cumulativeTaxPaid)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(!id.isEmpty) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(userId, forKey: .userId)
        try container.encode(amount, forKey: .amount)
        try container.encode(taxPaid, forKey: .taxPaid)
        try container.encode(creditedDate, forKey: .creditedDate)
        try container.encode(currency, forKey: .currency)
        try container.encode(incomeType, forKey: .incomeType)
        try container.encode(incomeTag, forKey: .incomeTag)
        try container.encode(avgAmount, forKey: .avgAmount)
        try container.encode(avgTaxPaid, forKey: .avgTaxPaid)
        try container.encode(cumulativeAmount, forKey: .cumulativeAmount)
        try container.encode(cumulativeTaxPaid, forKey: .cumulativeTaxPaid)
    }
}
