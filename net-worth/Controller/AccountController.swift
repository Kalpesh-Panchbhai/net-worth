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
    
    private var financeController = FinanceController()
    
    public func addTransaction(accountID: String, accountModel: AccountModel) {
        var balanceChange = 0.0
        if(accountModel.accountType == "Saving" || accountModel.accountType == "Credit Card" || accountModel.accountType == "Loan" || accountModel.accountType == "Other") {
            balanceChange = accountModel.currentBalance
        } else {
            balanceChange = accountModel.totalShares
        }
        
        let newTransaction = AccountTrans(timestamp: Date(), balanceChange: balanceChange)
        
        AccountViewModel().addTransaction(accountID: accountID, accountTransaction: newTransaction)
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
        let newAccount = Accountss(accountType: accountModel.accountType, accountName: accountModel.accountName, currentBalance: accountModel.currentBalance, totalShares: accountModel.totalShares, paymentReminder: accountModel.paymentReminder, paymentDate: accountModel.paymentDate, symbol: accountModel.symbol, currency: accountModel.currency)
        
        var accountID = AccountViewModel().addAccount(account: newAccount)
        
        addTransaction(accountID: accountID, accountModel: accountModel)
    }
    
    public func fetchTotalBalance() async throws -> BalanceModel {
        
        let request = Account.fetchRequest()
        var accounts: [Account] = []
        do{
            accounts = try viewContext.fetch(request)
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return try await withThrowingTaskGroup(of: BalanceModel.self) { group in
            
            var balance = BalanceModel()
            
            for account in accounts {
                if(!(account.accounttype == "Saving" || account.accounttype == "Credit Card" || account.accounttype == "Loan" || account.accounttype == "Other")) {
                    group.addTask {
                        var balanceModel = BalanceModel(totalChange: 1.0, oneDayChange: 1.0)
                        if(account.currency != SettingsController().getDefaultCurrency().code) {
                            var financeDetailModel = FinanceDetailModel()
                            financeDetailModel = try await FinanceController().getSymbolDetails(accountCurrency: account.currency!)
                            let regularMarketPrice = financeDetailModel.regularMarketPrice ?? 1.0
                            let chartPreviousClose = financeDetailModel.chartPreviousClose ?? 1.0
                            balanceModel.totalChange = regularMarketPrice
                            balanceModel.oneDayChange = chartPreviousClose
                        }
                        let financeDetailModel = try await FinanceController().getSymbolDetails(symbol: account.symbol!)
                        balanceModel.totalChange = balanceModel.totalChange * (financeDetailModel.regularMarketPrice ?? 1.0 ) * account.totalshare
                        balanceModel.oneDayChange = balanceModel.oneDayChange * (financeDetailModel.chartPreviousClose ?? 1.0) * account.totalshare
                        balanceModel.oneDayChange = balanceModel.totalChange - balanceModel.oneDayChange
                        return balanceModel
                    }
                } else {
                    group.addTask {
                        var currentRate = BalanceModel(totalChange: 1.0, oneDayChange: 1.0)
                        if(account.currency != SettingsController().getDefaultCurrency().code) {
                            currentRate.totalChange = try await FinanceController().getSymbolDetails(accountCurrency: account.currency!).regularMarketPrice ?? 1.0
                        }
                        currentRate.totalChange = account.currentbalance * currentRate.totalChange
                        return currentRate
                    }
                }
            }
            
            for try await taskResult in group {
                balance.totalChange += taskResult.totalChange
                balance.oneDayChange += taskResult.oneDayChange
            }
            
            return balance
            
        }
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
