//
//  AccountTransactionRestModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/24.
//

import Foundation

struct AccountTransaction: Codable, Hashable {
    
    var accountId: Int
    var accountBrokerId: Int
    var value: Double
    var operation: String
    
    private enum CodingKeys: String, CodingKey {
        case accountId, accountBrokerId, value, operation
    }
    
    init(accountId: Int = 0, accountBrokerId: Int = 0, value: Double = 0.0, operation: String = "") {
        self.accountId = accountId
        self.accountBrokerId = accountBrokerId
        self.value = value
        self.operation = operation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountId = try container.decode(Int.self, forKey: .accountId)
        accountBrokerId = try container.decode(Int.self, forKey: .accountBrokerId)
        value = try container.decode(Double.self, forKey: .value)
        operation = try container.decode(String.self, forKey: .operation)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(accountBrokerId, forKey: .accountBrokerId)
        try container.encode(value, forKey: .value)
        try container.encode(operation, forKey: .operation)
    }
}
