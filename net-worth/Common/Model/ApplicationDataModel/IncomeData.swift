//
//  IncomeData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/12/23.
//

import Foundation

struct IncomeData: Codable {
    
    var id: String
    var amount: Double
    var taxpaid: Double
    var creditedOn: Date
    var currency: String
    var type: String
    var tag: String
}
