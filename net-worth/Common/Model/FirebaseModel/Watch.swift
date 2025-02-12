//
//  Watch.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//
import Foundation

struct Watch: Codable, Hashable {
    
    var id: String
    var userId: String
    var name: String
    var accountList: [String]
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, name, accountList
    }
    
    init(id: String = "", userId: String = "", name: String = "", accountList: [String] = []) {
        self.id = ""
        self.userId = userId
        self.name = name
        self.accountList = accountList
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        accountList = try container.decode([String].self, forKey: .accountList)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(!id.isEmpty) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(accountList, forKey: .accountList)
    }
}
