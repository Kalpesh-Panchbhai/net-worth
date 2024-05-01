//
//  IncomeRequest.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct IncomeRequest: Codable {
    var amount: Double
    var taxPaid: Double
    var currency: String
    var incomeType: String
    var incomeTag: String
    var creditedOn: String
    var user: String
}
