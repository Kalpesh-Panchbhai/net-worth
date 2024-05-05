//
//  AccountRestModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/05/24.
//

import Foundation

struct AccountRestModel: Codable {
    
    var id: String
    var accountType: String
    var loanType: String
    var accountName: String
    var currentBalance: Double
    var paymentReminder: Bool
    var paymentDate: Int
    var currency: String
    var active: Bool
    var userId: String
    var accountOpenedDate: String
    
    private enum CodingKeys: String, CodingKey {
        case id, accountType, loanType, accountName, currentBalance, paymentReminder, paymentDate, currency, active, userId, accountOpenedDate
    }
    
    init(id: String = "", accountType: String = "", loanType: String = "", accountName: String = "", currentBalance: Double = 0.0, paymentReminder: Bool = false, paymentDate: Int = 0, currency: String = "", active: Bool = true, userId: String = "", accountOpenedDate: String = "") {
        self.id = id
        self.accountType = accountType
        self.loanType = loanType
        self.accountName = accountName
        self.currentBalance = currentBalance
        self.paymentReminder = paymentReminder
        self.paymentDate = paymentDate
        self.currency = currency
        self.active = active
        self.userId = userId
        self.accountOpenedDate = accountOpenedDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        accountType = try container.decode(String.self, forKey: .accountType)
        loanType = try container.decode(String.self, forKey: .loanType)
        accountName = try container.decode(String.self, forKey: .accountName)
        currentBalance = try container.decode(Double.self, forKey: .currentBalance)
        paymentDate = try container.decode(Int.self, forKey: .paymentDate)
        paymentReminder = try container.decode(Bool.self, forKey: .paymentReminder)
        currency = try container.decode(String.self, forKey: .currency)
        active = try container.decode(Bool.self, forKey: .active)
        userId = try container.decode(String.self, forKey: .userId)
        accountOpenedDate = ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if(!id.isEmpty) {
            try container.encode(id, forKey: .id)
        }
        try container.encode(accountType, forKey: .accountType)
        try container.encode(loanType, forKey: .loanType)
        try container.encode(accountName, forKey: .accountName)
        try container.encode(currentBalance, forKey: .currentBalance)
        try container.encode(paymentDate, forKey: .paymentDate)
        try container.encode(paymentReminder, forKey: .paymentReminder)
        try container.encode(currency, forKey: .currency)
        try container.encode(active, forKey: .active)
        try container.encode(userId, forKey: .userId)
        try container.encode(accountOpenedDate, forKey: .accountOpenedDate)
    }
}
