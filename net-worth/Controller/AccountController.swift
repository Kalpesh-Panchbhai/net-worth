//
//  ItemViewController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import Foundation
import SwiftUI

class AccountController {
    
    let viewContext = PersistenceController.shared.container.viewContext
    
    public func addAccount(accountType: String, accountName: String, currentBalance: String, paymentReminder: Bool, paymentDate: Int) {
        let newAccount = Account(context: viewContext)
        newAccount.timestamp = Date()
        newAccount.accounttype = accountType
        newAccount.accountname =  accountName
        if accountType == "Loan" || accountType == "Credit Card" {
            newAccount.currentbalance = Double((currentBalance as NSString).doubleValue) * -1
        }else{
            newAccount.currentbalance = Double((currentBalance as NSString).doubleValue)
        }
        newAccount.paymentReminder = paymentReminder
        newAccount.paymentDate = Int16(paymentDate)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    public func getAccountTotalBalance() -> Double {
        var balance = 0.0
        let request = Account.fetchRequest()
        var accounts: [Account] = []
        do{
            accounts = try viewContext.fetch(request)
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        for account in accounts {
            balance += account.currentbalance
        }
        return balance
    }
    
}
