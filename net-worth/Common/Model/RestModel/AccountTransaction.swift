//
//  AccountTransactionRestModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/24.
//

import Foundation

struct AccountTransaction: Codable, Hashable {
    
    var id: String
    var accountId: String
    var timestamp: String
    var amount: Double
    var paid: Bool
    var operation: String
    var isAccountTransaction: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, accountId, timestamp, amount, paid, operation, isAccountTransaction
    }
    
    init(id: String = "", accountId: String = "", timestamp: String = "", amount: Double = 0.0, paid: Bool = true, operation: String = "", isAccountTransaction: Bool) {
        self.id = id
        self.accountId = accountId
        self.timestamp = timestamp
        self.amount = amount
        self.paid = paid
        self.operation = operation
        self.isAccountTransaction = isAccountTransaction
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountId = try container.decode(String.self, forKey: .accountId)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        amount = try container.decode(Double.self, forKey: .amount)
        paid = try container.decode(Bool.self, forKey: .paid)
        operation = try container.decode(String.self, forKey: .operation)
        isAccountTransaction = try container.decode(Bool.self, forKey: .isAccountTransaction)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(!id.isEmpty) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(accountId, forKey: .accountId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(amount, forKey: .amount)
        try container.encode(paid, forKey: .paid)
        try container.encode(operation, forKey: .operation)
        try container.encode(isAccountTransaction, forKey: .isAccountTransaction)
    }
}
