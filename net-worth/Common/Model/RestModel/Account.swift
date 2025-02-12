//
//  Account.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/05/24.
//

import Foundation

struct Account: Codable, Hashable {
    
    var id: Int
    var userId: Int
    var accountName: String
    var accountType: String
    var loanType: String
    var currency: String
    var active: Bool
    var balance: BalanceAccount
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, accountName, accountType, loanType, currency, active, balance
    }
    
    init(id: Int = 0, userId: Int = 0, accountName: String = "", accountType: String = "", loanType: String = "", currency: String = "", active: Bool = true, balance: BalanceAccount = BalanceAccount()) {
        self.id = id
        self.userId = userId
        self.accountName = accountName
        self.accountType = accountType
        self.loanType = loanType
        self.currency = currency
        self.active = active
        self.balance = balance
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        accountName = try container.decode(String.self, forKey: .accountName)
        accountType = try container.decode(String.self, forKey: .accountType)
        loanType = try container.decode(String.self, forKey: .loanType)
        currency = try container.decode(String.self, forKey: .currency)
        active = try container.decode(Bool.self, forKey: .active)
        balance = try container.decode(BalanceAccount.self, forKey: .balance)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(id != 0) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(userId, forKey: .userId)
        try container.encode(accountName, forKey: .accountName)
        try container.encode(accountType, forKey: .accountType)
        try container.encode(loanType, forKey: .loanType)
        try container.encode(currency, forKey: .currency)
        try container.encode(active, forKey: .active)
        try container.encode(balance, forKey: .balance)
    }
}
