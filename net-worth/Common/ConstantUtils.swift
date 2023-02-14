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
        case symbol = "Symbol"
        case other = "Other"
    }

    
    static var userCollectionName = "users"
    static var incomeCollectionName = "incomes"
    static var accountCollectionName = "accounts"
    static var accountTransactionCollectionName = "accountsTransaction"
    static var watchCollectionName = "watches"
    
    static var incomeKeyAmount = "amount"
    static var incomeKeyCreditedOn = "creditedOn"
    static var incomeKeyCurrency = "currency"
    static var incomeKeyIncomeType = "incomeType"
    
    static var accountKeyAccountName = "accountName"
    static var accountKeyAccountType = "accountType"
    static var accountKeyCurrency = "currency"
    static var accountKeyCurrentBalance = "currentBalance"
    static var accountKeyPaymentDate = "paymentDate"
    static var accountKeyPaymentReminder = "paymentReminder"
    static var accountKeySymbol = "symbol"
    static var accountKeyTotalShares = "totalShares"
    
    static var accountTransactionKeyBalanceChange = "balanceChange"
    static var accountTransactionKeytimestamp = "timestamp"
    
    static var watchKeyWatchName = "accountName"
    static var watchKeyAccountID = "accountID"
}
