//
//  IncomeResponse.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct IncomeDeleteResponse: Codable {
    var id: String
}

struct IncomeDeleteResultResponse: Codable {
    var data: [IncomeDeleteResponse]
}

struct IncomeDeleteMainResponse: Codable {
    var result: IncomeDeleteResultResponse
}
