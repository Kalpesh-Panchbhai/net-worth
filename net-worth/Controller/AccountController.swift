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
    
    private var notificationController = NotificationController()
    
    private var mutualFundController = MutualFundController()
    
    public func addTransaction(accountModel: AccountModel) {
        let newTransaction = AccountTransaction(context: viewContext)
        newTransaction.sysid = UUID()
        newTransaction.timestamp = Date()
        newTransaction.accountsysid = accountModel.sysId
        if(accountModel.accountType == "Stock" || accountModel.accountType == "Mutual Fund") {
            newTransaction.balancechange = accountModel.totalShares
        } else {
            newTransaction.balancechange = accountModel.currentBalance
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    public func getAccountTransaction(sysId: UUID) -> [AccountTransaction] {
        let request = AccountTransaction.fetchRequest()
        let sortDescriptors = NSSortDescriptor(key: "timestamp", ascending: false)
        request.sortDescriptors = [sortDescriptors]
        request.predicate = NSPredicate(
            format: "accountsysid= %@", sysId.uuidString
        )
        var accountTransactionList: [AccountTransaction]
        do{
            accountTransactionList = try viewContext.fetch(request)
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return accountTransactionList
    }
    
    public func deleteAccountTransaction(accountSysId: UUID) {
        let transactionList = getAccountTransaction(sysId: accountSysId)
        
        for transaction in transactionList {
            viewContext.delete(transaction)
            
            do {
                try viewContext.save()
            }catch {
                viewContext.rollback()
                print("Failed to delete account transaction \(error)")
            }
        }
    }
    
    public func addAccount(accountModel: AccountModel) {
        let newAccount = Account(context: viewContext)
        newAccount.sysid = UUID()
        newAccount.timestamp = Date()
        newAccount.accounttype = accountModel.accountType
        newAccount.accountname =  accountModel.accountName
        newAccount.currentbalance = accountModel.currentBalance
        newAccount.totalshare = accountModel.totalShares
        newAccount.paymentreminder = accountModel.paymentReminder
        newAccount.paymentdate = Int16(accountModel.paymentDate)
        
        do {
            try viewContext.save()
            accountModel.sysId = newAccount.sysid!
            addTransaction(accountModel: accountModel)
            if(accountModel.paymentReminder) {
                notificationController.setNotification(id: newAccount.sysid!, day: accountModel.paymentDate, accountType: accountModel.accountType, accountName: accountModel.accountName)
            }
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
            if(account.accounttype == "Mutual Fund") {
                let mutualFund = mutualFundController.getMutualFund(name: account.accountname!)
                let currentBalance = account.totalshare * mutualFund.rate
                balance += currentBalance
            }else {
                balance += account.currentbalance
            }
        }
        return balance
    }
    
    public func getAccount(uuid: UUID) -> Account {
        let request = Account.fetchRequest()
        request.predicate = NSPredicate(
            format: "sysid = %@", uuid.uuidString
        )
        var account: Account
        do{
            account = try viewContext.fetch(request).first!
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return account
    }
    
    public func getAccount(accountType: String) -> [Account] {
        let request = Account.fetchRequest()
        request.predicate = NSPredicate(
            format: "accounttype = %@", accountType
        )
        var accountList: [Account]
        do{
            accountList = try viewContext.fetch(request)
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return accountList
    }
    
    public func deleteAccount(account: Account) {
        deleteAccountTransaction(accountSysId: account.sysid!)
        
        viewContext.delete(account)
        do {
            notificationController.removeNotification(id: account.sysid!)
            try viewContext.save()
        }catch {
            viewContext.rollback()
            print("Failed to delete account \(error)")
        }
    }
    
    public func updateAccount() {
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
            print("Failed to update account \(error)")
        }
    }
}
