//
//  AccountInBroker.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import Foundation

struct AccountInBroker: Codable, Hashable {
    
    var id: String
    var accountId: String
    var symbol: String
    var name: String
    var currentUnit: Double
    var balance: BalanceAccount
    
    private enum CodingKeys: String, CodingKey {
        case id, accountId, symbol, name, currentUnit, balance
    }
    
    init(id: String = "", accountId: String = "", symbol: String = "", name: String = "", currentUnit: Double = 0.0, balance: BalanceAccount = BalanceAccount()) {
        self.id = id
        self.accountId = accountId
        self.symbol = symbol
        self.name = name
        self.currentUnit = currentUnit
        self.balance = balance
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountId = try container.decode(String.self, forKey: .accountId)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        currentUnit = try container.decode(Double.self, forKey: .currentUnit)
        balance = try container.decode(BalanceAccount.self, forKey: .balance)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(!id.isEmpty) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(accountId, forKey: .accountId)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(name, forKey: .name)
        try container.encode(balance, forKey: .balance)
        try container.encode(currentUnit, forKey: .currentUnit)
    }
}
