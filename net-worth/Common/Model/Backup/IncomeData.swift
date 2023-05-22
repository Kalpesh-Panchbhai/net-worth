//
//  IncomeData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

struct IncomeData: Codable {
    
    var amount: Double
    var taxpaid: Double
    var creditedOn: Date
    var currency: String
    var type: String
    var tag: String
    
    var avgAmount: Double
    var avgTaxPaid: Double
    var cumulativeAmount: Double
    var cumulativeTaxPaid: Double
    
    var animate: Bool
    
}
