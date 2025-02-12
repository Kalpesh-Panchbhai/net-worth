//
//  Watch.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//
import Foundation

struct Watch: Codable, Hashable {
    
    var id: Int
    var userId: Int
    var name: String
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, name
    }
    
    init(id: Int = 0, userId: Int = 0, name: String = "") {
        self.id = id
        self.userId = userId
        self.name = name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(id != 0) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
    }
}
