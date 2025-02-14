//
//  Account.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/05/24.
//

import Foundation

struct AccountRestModel: Codable, Hashable {
    
    var id: Int
    var userId: Int
    var name: String
    var type: String
    var loanType: String
    var currency: String
    var active: Bool
    var value: AccountValue
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, name, type, loanType, currency, active, value
    }
    
    init(id: Int = 0, userId: Int = 0, name: String = "", accountType: String = "", loanType: String = "", currency: String = "", active: Bool = true, balance: AccountValue = AccountValue()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.type = accountType
        self.loanType = loanType
        self.currency = currency
        self.active = active
        self.value = balance
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        loanType = try container.decode(String.self, forKey: .loanType)
        currency = try container.decode(String.self, forKey: .currency)
        active = try container.decode(Bool.self, forKey: .active)
        value = try container.decode(AccountValue.self, forKey: .value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(id != 0) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(loanType, forKey: .loanType)
        try container.encode(currency, forKey: .currency)
        try container.encode(active, forKey: .active)
    }
}
