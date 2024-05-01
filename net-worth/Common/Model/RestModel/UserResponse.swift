//
//  UserResponse.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct UserResponse: Codable {
    var userId: String
    var id: String
}

struct UserResultResponse: Codable {
    var data: UserResponse
}

struct UserMainResponse: Codable {
    var result: UserResultResponse
}
