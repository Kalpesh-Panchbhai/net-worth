//
//  Account.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Account: Codable, Hashable {
    
    @DocumentID var id: String?
    var accountType: String
    var accountName: String
    var currentBalance: Double
    var totalShares: Double
    var paymentReminder: Bool
    var paymentDate: Int
    var symbol: String
    var currency: String
    
    init() {
        self.accountType = ""
        self.accountName = ""
        self.currentBalance = 0.0
        self.totalShares = 0.0
        self.paymentReminder = false
        self.paymentDate = 0
        self.symbol = ""
        self.currency = ""
    }
    
    init(id: String) {
        self.id = id
        self.accountType = ""
        self.accountName = ""
        self.currentBalance = 0.0
        self.totalShares = 0.0
        self.paymentReminder = false
        self.paymentDate = 0
        self.symbol = ""
        self.currency = ""
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(DocumentID<String>.self, forKey: .id)
        self.accountType = try container.decode(String.self, forKey: .accountType)
        self.accountName = try container.decode(String.self, forKey: .accountName)
        self.currentBalance = try container.decode(Double.self, forKey: .currentBalance)
        self.totalShares = try container.decode(Double.self, forKey: .totalShares)
        self.paymentReminder = try container.decode(Bool.self, forKey: .paymentReminder)
        self.paymentDate = try container.decode(Int.self, forKey: .paymentDate)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.currency = try container.decode(String.self, forKey: .currency)
    }
    
    init(doc: QueryDocumentSnapshot) {
        id = doc.documentID
        accountType = doc[ConstantUtils.accountKeyAccountType] as? String ?? ""
        accountName = doc[ConstantUtils.accountKeyAccountName] as? String ?? ""
        currentBalance = doc[ConstantUtils.accountKeyCurrentBalance] as? Double ?? 0.0
        totalShares = doc[ConstantUtils.accountKeyTotalShares] as? Double ?? 0.0
        paymentReminder = doc[ConstantUtils.accountKeyPaymentReminder] as? Bool ?? false
        paymentDate = doc[ConstantUtils.accountKeyPaymentDate] as? Int ?? 0
        symbol = doc[ConstantUtils.accountKeySymbol] as? String ?? ""
        currency = doc[ConstantUtils.accountKeyCurrency] as? String ?? ""
    }
    
    init(accountType: String, accountName: String, currentBalance: Double, totalShares: Double, paymentReminder: Bool, paymentDate: Int, symbol: String, currency: String) {
        self.accountType = accountType
        self.accountName = accountName
        self.currentBalance = currentBalance
        self.totalShares = totalShares
        self.paymentReminder = paymentReminder
        self.paymentDate = paymentDate
        self.symbol = symbol
        self.currency = currency
    }
    
}
