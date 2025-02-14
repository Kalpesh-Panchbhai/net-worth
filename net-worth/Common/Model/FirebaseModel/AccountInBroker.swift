//
//  AccountInBroker.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import Foundation

struct AccountInBroker: Codable, Hashable {
    
    var id: Int
    var accountId: Int
    var symbol: String
    var name: String
    var currentUnit: Double
    var value: AccountValue
    
    private enum CodingKeys: String, CodingKey {
        case id, accountId, symbol, name, currentUnit, value
    }
    
    init(id: Int = 0, accountId: Int = 0, symbol: String = "", name: String = "", currentUnit: Double = 0.0, value: AccountValue = AccountValue()) {
        self.id = id
        self.accountId = accountId
        self.symbol = symbol
        self.name = name
        self.currentUnit = currentUnit
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountId = try container.decode(Int.self, forKey: .accountId)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        currentUnit = try container.decode(Double.self, forKey: .currentUnit)
        value = try container.decode(AccountValue.self, forKey: .value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(id != 0) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(accountId, forKey: .accountId)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(name, forKey: .name)
        try container.encode(currentUnit, forKey: .currentUnit)
        try container.encode(value, forKey: .value)
    }
}
