//
//  UserResponse.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct TypeValueRestModel: Codable {
    var id: Int
    var userId: Int
    var name: String
    var isDefault: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, name, isDefault
    }
    
    init(id: Int = 0, userId: Int = 0, name: String = "", isDefault: Bool = false) {
        self.id = id
        self.userId = userId
        self.name = name
        self.isDefault = isDefault
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        isDefault = try container.decode(Bool.self, forKey: .isDefault)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(id != 0) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(isDefault, forKey: .isDefault)
    }
}
