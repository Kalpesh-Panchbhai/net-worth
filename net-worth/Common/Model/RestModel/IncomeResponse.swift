//
//  IncomeResponse.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct IncomeResponse: Codable {
    var id: String
    var amount: Double
    var taxPaid: Double
    var currency: String
    var incomeType: String
    var incomeTag: String
    var creditedOn: String
    var user: String
}

struct IncomeResultResponse: Codable {
    var data: [IncomeResponse]
}

struct IncomeMainResponse: Codable {
    var result: IncomeResultResponse
}
