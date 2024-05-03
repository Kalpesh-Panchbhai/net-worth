//
//  UserResponse.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

struct TypeValueRestModel: Codable {
    var id: String
    var name: String
    var userId: String
    var isDefault: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, name, userId, isDefault
    }
    
    init(id: String = "", name: String = "", userId: String = "", isDefault: Bool = false) {
        self.id = id
        self.userId = userId
        self.name = name
        self.isDefault = isDefault
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        userId = try container.decode(String.self, forKey: .userId)
        isDefault = try container.decode(Bool.self, forKey: .isDefault)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(!id.isEmpty) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(name, forKey: .name)
        try container.encode(userId, forKey: .userId)
        try container.encode(isDefault, forKey: .isDefault)
    }
}
