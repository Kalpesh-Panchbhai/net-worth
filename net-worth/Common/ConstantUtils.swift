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
    
    static var incomeKeyAmount = "amount"
    static var incomeKeyCreditedOn = "creditedon"
    static var incomeKeyIncomeType = "incometype"
    static var incomeKeyCurrency = "currency"
    
    
}
