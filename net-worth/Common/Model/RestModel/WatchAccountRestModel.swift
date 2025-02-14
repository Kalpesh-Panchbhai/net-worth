//
//  Watch.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//
import Foundation

struct WatchAccountRestModel: Codable, Hashable {
    
    var id: Int
    var accountId: Int
    var watchId: Int
    
    private enum CodingKeys: String, CodingKey {
        case id, accountId, watchId
    }
    
    init(id: Int = 0, accountId: Int = 0, watchId: Int = 0) {
        self.id = id
        self.accountId = accountId
        self.watchId = watchId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountId = try container.decode(Int.self, forKey: .accountId)
        watchId = try container.decode(Int.self, forKey: .watchId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(id != 0) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(accountId, forKey: .accountId)
        try container.encode(watchId, forKey: .watchId)
    }
}
