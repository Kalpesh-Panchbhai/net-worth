//
//  UserResponse.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct UserRestModel: Codable {
    
    var id: Int
    var userId: String
    
    private enum CodingKeys: String, CodingKey {
        case id, userId
    }
    
    init(id: Int = 0, userId: String = "") {
        self.id = id
        self.userId = userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
    }
}
