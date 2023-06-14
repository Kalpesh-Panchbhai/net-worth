//
//  IncomeCalculation.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/06/23.
//

import Foundation

class IncomeCalculation: Income {
    
    var avgAmount: Double
    var avgTaxPaid: Double
    var cumulativeAmount: Double
    var cumulativeTaxPaid: Double
    
    init(id: String? = nil, amount: Double, taxpaid: Double, creditedOn: Date, currency: String, type: String, tag: String, avgAmount: Double, avgTaxPaid: Double, cumulativeAmount: Double, cumulativeTaxPaid: Double) {
        self.avgAmount = avgAmount
        self.avgTaxPaid = avgTaxPaid
        self.cumulativeAmount = cumulativeAmount
        self.cumulativeTaxPaid = cumulativeTaxPaid
        super.init(id: id, amount: amount, taxpaid: taxpaid, creditedOn: creditedOn, currency: currency, type: type, tag: tag)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
}
