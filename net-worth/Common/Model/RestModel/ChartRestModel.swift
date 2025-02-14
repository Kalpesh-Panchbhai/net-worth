//
//  ChartRest.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 08/05/24.
//

import Foundation

struct ChartRestModel: Codable {
    
    var id: String
    var accountId: String
    var accountBrokerId: String
    var date: String
    var value: Double
}
