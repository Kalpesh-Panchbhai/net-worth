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
    var loanType: String
    var accountName: String
    var currentBalance: Double
    var paymentReminder: Bool
    var paymentDate: Int
    var currency: String
    var active: Bool
    
    init(id: String = "", accountType: String = "", loanType: String = "", accountName: String = "", currentBalance: Double = 0.0, paymentReminder: Bool = false, paymentDate: Int = 0, currency: String = "", active: Bool = true) {
        self.id = id
        self.accountType = accountType
        self.loanType = loanType
        self.accountName = accountName
        self.currentBalance = currentBalance
        self.paymentReminder = paymentReminder
        self.paymentDate = paymentDate
        self.currency = currency
        self.active = active
    }
    
    init(doc: QueryDocumentSnapshot) {
        id = doc.documentID
        accountType = doc[ConstantUtils.accountKeyAccountType] as? String ?? ""
        loanType = doc[ConstantUtils.accountKeyLoanType] as? String ?? ""
        accountName = doc[ConstantUtils.accountKeyAccountName] as? String ?? ""
        currentBalance = doc[ConstantUtils.accountKeyCurrentBalance] as? Double ?? 0.0
        paymentReminder = doc[ConstantUtils.accountKeyPaymentReminder] as? Bool ?? false
        paymentDate = doc[ConstantUtils.accountKeyPaymentDate] as? Int ?? 0
        currency = doc[ConstantUtils.accountKeyCurrency] as? String ?? ""
        active =  doc[ConstantUtils.accountKeyActive] as? Bool ?? true
    }
}