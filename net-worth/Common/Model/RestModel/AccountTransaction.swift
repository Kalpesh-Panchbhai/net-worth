//
//  AccountTransactionRestModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/24.
//

import Foundation

struct AccountTransaction: Codable, Hashable {
    
    var accountId: Int
    var amount: Double
    var operation: String
    var isAccountTransaction: Bool
    
    private enum CodingKeys: String, CodingKey {
        case accountId, amount, operation, isAccountTransaction
    }
    
    init(accountId: Int = 0, amount: Double = 0.0, operation: String = "", isAccountTransaction: Bool) {
        self.accountId = accountId
        self.amount = amount
        self.operation = operation
        self.isAccountTransaction = isAccountTransaction
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountId = try container.decode(Int.self, forKey: .accountId)
        amount = try container.decode(Double.self, forKey: .amount)
        operation = try container.decode(String.self, forKey: .operation)
        isAccountTransaction = try container.decode(Bool.self, forKey: .isAccountTransaction)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(amount, forKey: .amount)
        try container.encode(operation, forKey: .operation)
        try container.encode(isAccountTransaction, forKey: .isAccountTransaction)
    }
}
