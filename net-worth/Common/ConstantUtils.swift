//
//  ConstantUtils.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 26/11/22.
//

import Foundation

class ConstantUtils {
    
    enum AccountType: String, CaseIterable {
        case none = "None"
        case saving = "Saving"
        case creditcard = "Credit Card"
        case loan = "Loan"
        case other = "Other"
    }

    
    static var userCollectionName = "users"
    static var incomeCollectionName = "incomes"
    static var incomeTagCollectionName = "incometags"
    static var incomeTypeCollectionName = "incometypes"
    static var accountCollectionName = "accounts"
    static var accountTransactionCollectionName = "accountsTransaction"
    static var watchCollectionName = "watches"
    
    static var incomeKeyAmount = "amount"
    static var incomeKeyTaxPaid = "taxpaid"
    static var incomeKeyCreditedOn = "creditedOn"
    static var incomeKeyCurrency = "currency"
    static var incomeKeyIncomeType = "type"
    static var incomeKeyIncomeTag = "tag"
    
    static var accountKeyAccountName = "accountName"
    static var accountKeyAccountType = "accountType"
    static var accountKeyLoanType = "loanType"
    static var accountKeyCurrency = "currency"
    static var accountKeyCurrentBalance = "currentBalance"
    static var accountKeyPaymentDate = "paymentDate"
    static var accountKeyPaymentReminder = "paymentReminder"
    static var accountKeySymbol = "symbol"
    static var accountKeyActive = "active"
    
    static var accountTransactionKeyBalanceChange = "balanceChange"
    static var accountTransactionKeytimestamp = "timestamp"
    static var accountTransactionKeyCurrentBalance = "currentBalance"
    static var accountTransactionKeyPaid = "paid"
    
    static var watchKeyWatchName = "accountName"
    static var watchKeyAccountID = "accountID"
    
    static var incomeTagKeyName = "name"
    static var incomeTagKeyIsDefault = "isdefault"
    
    static var incomeTypeKeyName = "name"
    static var incomeTypeKeyIsDefault = "isdefault"
}
