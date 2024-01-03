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
        case broker = "Broker"
        case other = "Other"
    }
    
    static var userCollectionName = "users"
    static var incomeCollectionName = "incomes"
    static var incomeTagCollectionName = "incometags"
    static var incomeTypeCollectionName = "incometypes"
    static var accountCollectionName = "accounts"
    static var accountTransactionCollectionName = "accountsTransaction"
    static var accountBrokerCollectionName = "accountsBroker"
    static var watchCollectionName = "watches"
    
    static var incomeKeyAmount = "amount"
    static var incomeKeyTaxPaid = "taxpaid"
    static var incomeKeyCreditedOn = "creditedOn"
    static var incomeKeyCreatedDate = "createdDate"
    static var incomeKeyCurrency = "currency"
    static var incomeKeyIncomeType = "type"
    static var incomeKeyIncomeTag = "tag"
    static var incomeKeyDeleted = "deleted"
    
    static var accountKeyAccountName = "accountName"
    static var accountKeyAccountType = "accountType"
    static var accountKeyLoanType = "loanType"
    static var accountKeyCurrency = "currency"
    static var accountKeyCurrentBalance = "currentBalance"
    static var accountKeyPaymentDate = "paymentDate"
    static var accountKeyPaymentReminder = "paymentReminder"
    static var accountKeySymbol = "symbol"
    static var accountKeyActive = "active"
    static var accountKeyLastUpdated = "lastUpdated"
    
    static var accountTransactionKeyBalanceChange = "balanceChange"
    static var accountTransactionKeytimestamp = "timestamp"
    static var accountTransactionKeyCurrentBalance = "currentBalance"
    static var accountTransactionKeyPaid = "paid"
    static var accountTransactionKeyCreatedDate = "createdDate"
    
    static var accountBrokerKeyCurrentUnit = "currentUnit"
    static var accountBrokerKeySymbol = "symbol"
    static var accountBrokerKeyName = "name"
    static var accountBrokerKeyTimeStamp = "timestamp"
    static var accountBrokerKeyTimeStampLastUpdated = "lastUpdated"
    
    static var watchKeyWatchName = "accountName"
    static var watchKeyAccountID = "accountID"
    
    static var incomeTagKeyName = "name"
    static var incomeTagKeyIsDefault = "isdefault"
    
    static var incomeTypeKeyName = "name"
    static var incomeTypeKeyIsDefault = "isdefault"
    
    static var newTransactionImageName = "square.and.pencil"
    static var deleteImageName = "trash"
    static var infoIconImageName = "info.square"
    static var arrowUpImageName = "arrow.up"    
    static var arrowDownImageName = "arrow.down"
    static var checkmarkImageName = "checkmark"
    static var backbuttonImageName = "chevron.left"
    static var notificationOnImageName = "bell.fill"
    static var notificationOffImageName = "bell.slash.fill"
    static var plusImageName = "plus"
    static var menuImageName = "ellipsis"
    static var notBookmarkImageName = "bookmark"
    static var bookmarkImageName = "bookmark.fill"
    static var chartImageName = "chart.line.uptrend.xyaxis"
    
    static var noneAccountType = "None"
    static var savingAccountType = "Saving"
    static var creditCardAccountType = "Credit Card"
    static var loanAccountType = "Loan"
    static var brokerAccountType = "Broker"
    static var otherAccountType = "Other"
    
    static var oneMonthRange = "1M"
    static var threeMonthRange = "3M"
    static var sixMonthRange = "6M"
    static var oneYearRange = "1Y"
    static var twoYearRange = "2Y"
    static var fiveYearRange = "5Y"
    static var allRange = "All"
    
}
