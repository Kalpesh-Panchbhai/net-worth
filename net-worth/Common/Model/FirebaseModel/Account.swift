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
    
    var id: String?
    var accountType: String
    var loanType: String
    var accountName: String
    var currentBalance: Double
    var paymentReminder: Bool
    var paymentDate: Int
    var currency: String
    var active: Bool
    var lastUpdated: Date
    var deleted: Bool
    
    init(id: String? = nil, accountType: String = "", loanType: String = "", accountName: String = "", currentBalance: Double = 0.0, paymentReminder: Bool = false, paymentDate: Int = 0, currency: String = "", active: Bool = true, lastUpdated: Date = Date.now, deleted: Bool = false) {
        self.id = id
        self.accountType = accountType
        self.loanType = loanType
        self.accountName = accountName
        self.currentBalance = currentBalance
        self.paymentReminder = paymentReminder
        self.paymentDate = paymentDate
        self.currency = currency
        self.active = active
        self.lastUpdated = lastUpdated
        self.deleted = deleted
    }
    
    init(doc: QueryDocumentSnapshot) {
        self.id = doc.documentID
        self.accountType = doc[ConstantUtils.accountKeyAccountType] as? String ?? ""
        self.loanType = doc[ConstantUtils.accountKeyLoanType] as? String ?? ""
        self.accountName = doc[ConstantUtils.accountKeyAccountName] as? String ?? ""
        self.currentBalance = doc[ConstantUtils.accountKeyCurrentBalance] as? Double ?? 0.0
        self.paymentReminder = doc[ConstantUtils.accountKeyPaymentReminder] as? Bool ?? false
        self.paymentDate = doc[ConstantUtils.accountKeyPaymentDate] as? Int ?? 0
        self.currency = doc[ConstantUtils.accountKeyCurrency] as? String ?? ""
        self.active =  doc[ConstantUtils.accountKeyActive] as? Bool ?? true
        self.lastUpdated = (doc[ConstantUtils.accountKeyLastUpdated] as? Timestamp)?.dateValue() ?? Date()
        self.deleted =  doc[ConstantUtils.accountKeyDeleted] as? Bool ?? false
    }
}
