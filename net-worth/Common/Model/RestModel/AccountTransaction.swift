//
//  AccountTransactionRestModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/24.
//

import Foundation

struct AccountTransaction: Codable, Hashable {
    
    var id: Int
    var accountId: Int
    var accountBrokerId: Int
    var transactionDate: String;
    var value: Double
    var operation: String
    
    private enum CodingKeys: String, CodingKey {
        case id, accountId, accountBrokerId, transactionDate, value, operation
    }
    
    init(id: Int = 0, accountId: Int = 0, accountBrokerId: Int = 0, transactionDate: String = "", value: Double = 0.0, operation: String = "") {
        self.id = id
        self.accountId = accountId
        self.accountBrokerId = accountBrokerId
        self.transactionDate = transactionDate
        self.value = value
        self.operation = operation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        accountId = try container.decode(Int.self, forKey: .accountId)
        accountBrokerId = try container.decode(Int.self, forKey: .accountBrokerId)
        transactionDate = try container.decode(String.self, forKey: .transactionDate)
        value = try container.decode(Double.self, forKey: .value)
        operation = try container.decode(String.self, forKey: .operation)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(id != 0) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(accountId, forKey: .accountId)
        try container.encode(accountBrokerId, forKey: .accountBrokerId)
        try container.encode(transactionDate, forKey: .transactionDate)
        try container.encode(value, forKey: .value)
        try container.encode(operation, forKey: .operation)
    }
}
