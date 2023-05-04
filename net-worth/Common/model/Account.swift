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
    var paymentReminder: Bool
    var paymentDate: Int
    var currency: String
    var active: Bool
    
    init() {
        self.accountType = ""
        self.accountName = ""
        self.currentBalance = 0.0
        self.paymentReminder = false
        self.paymentDate = 0
        self.currency = ""
        self.active = true
    }
    
    init(id: String) {
        self.id = id
        self.accountType = ""
        self.accountName = ""
        self.currentBalance = 0.0
        self.paymentReminder = false
        self.paymentDate = 0
        self.currency = ""
        self.active = true
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._id = try container.decode(DocumentID<String>.self, forKey: .id)
        self.accountType = try container.decode(String.self, forKey: .accountType)
        self.accountName = try container.decode(String.self, forKey: .accountName)
        self.currentBalance = try container.decode(Double.self, forKey: .currentBalance)
        self.paymentReminder = try container.decode(Bool.self, forKey: .paymentReminder)
        self.paymentDate = try container.decode(Int.self, forKey: .paymentDate)
        self.currency = try container.decode(String.self, forKey: .currency)
        self.active = try container.decode(Bool.self, forKey: .active)
    }
    
    init(doc: QueryDocumentSnapshot) {
        id = doc.documentID
        accountType = doc[ConstantUtils.accountKeyAccountType] as? String ?? ""
        accountName = doc[ConstantUtils.accountKeyAccountName] as? String ?? ""
        currentBalance = doc[ConstantUtils.accountKeyCurrentBalance] as? Double ?? 0.0
        paymentReminder = doc[ConstantUtils.accountKeyPaymentReminder] as? Bool ?? false
        paymentDate = doc[ConstantUtils.accountKeyPaymentDate] as? Int ?? 0
        currency = doc[ConstantUtils.accountKeyCurrency] as? String ?? ""
        active =  doc[ConstantUtils.accountKeyActive] as? Bool ?? true
    }
    
    init(accountType: String, accountName: String, currentBalance: Double, paymentReminder: Bool, paymentDate: Int, currency: String, active: Bool) {
        self.accountType = accountType
        self.accountName = accountName
        self.currentBalance = currentBalance
        self.paymentReminder = paymentReminder
        self.paymentDate = paymentDate
        self.currency = currency
        self.active = active
    }
    
}
