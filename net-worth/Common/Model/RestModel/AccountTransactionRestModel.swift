//
//  AccountTransactionRestModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/24.
//

import Foundation

struct AccountTransactionRestModel: Codable {
    
    var id: String
    var accountId: String
    var timestamp: String
    var currentBalance: Double
    var paid: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, accountId, timestamp, currentBalance, paid
    }
    
    init(id: String = "", accountId: String = "", timestamp: String = "", currentBalance: Double = 0.0, paid: Bool = true) {
        self.id = id
        self.accountId = accountId
        self.timestamp = timestamp
        self.currentBalance = currentBalance
        self.paid = paid
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountId = try container.decode(String.self, forKey: .accountId)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        currentBalance = try container.decode(Double.self, forKey: .currentBalance)
        paid = try container.decode(Bool.self, forKey: .paid)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(!id.isEmpty) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(accountId, forKey: .accountId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(currentBalance, forKey: .currentBalance)
        try container.encode(paid, forKey: .paid)
    }
}
