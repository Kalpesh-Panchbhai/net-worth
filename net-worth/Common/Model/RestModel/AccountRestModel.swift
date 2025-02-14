//
//  Account.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/05/24.
//

import Foundation

struct AccountRestModel: Codable, Hashable {
    
    var id: String
    var userId: String
    var name: String
    var accountType: String
    var loanType: String
    var currency: String
    var active: Bool
    var value: AccountValue
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, name, accountType, loanType, currency, active, value
    }
    
    init(id: String = "", userId: String = "", name: String = "", accountType: String = "", loanType: String = "", currency: String = "", active: Bool = true, balance: AccountValue = AccountValue()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.accountType = accountType
        self.loanType = loanType
        self.currency = currency
        self.active = active
        self.value = balance
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        accountType = try container.decode(String.self, forKey: .accountType)
        loanType = try container.decode(String.self, forKey: .loanType)
        currency = try container.decode(String.self, forKey: .currency)
        active = try container.decode(Bool.self, forKey: .active)
        value = try container.decode(AccountValue.self, forKey: .value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(!id.isEmpty) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(accountType, forKey: .accountType)
        try container.encode(loanType, forKey: .loanType)
        try container.encode(currency, forKey: .currency)
        try container.encode(active, forKey: .active)
    }
}
