//
//  UserResponse.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct TypeValueResponse: Codable {
    var id: String
    var name: String
    var user: String
    var isDefault: Bool
}

struct TypeValueResultResponse: Codable {
    var data: [TypeValueResponse]
}

struct TypeValueMainResponse: Codable {
    var result: TypeValueResultResponse
}
