//
//  ItemViewController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class AccountController {
    
    private var notificationController = NotificationController()
    
    private var financeController = FinanceController()
    
    private func getAccountCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
    }
    
    public func addAccount(newAccount: Account) {
        do {
            let accountID = try getAccountCollection()
                .addDocument(from: newAccount).documentID
            addTransaction(accountID: accountID, account: newAccount)
        } catch {
            print(error)
        }
    }
    
    public func deleteAccount(account: Account) {
        CommonController.delete(collection: getAccountCollection().document(account.id!).collection(ConstantUtils.accountTransactionCollectionName))
        getAccountCollection().document(account.id!).delete()
    }
    
    public func updateAccount(account: Account) {
        do {
            try getAccountCollection()
                .document(account.id!)
                .setData(from: account, merge: true)
        } catch {
            print(error)
        }
    }
    
    public func getAccount(id: String) async throws -> Account {
        var account = Account()
        
        account = try await getAccountCollection()
            .document(id)
            .getDocument()
            .data(as: Account.self)
        
        return account
    }
    
    public func getAccountList() async throws -> [Account] {
        var accountList = [Account]()
        accountList = try await getAccountCollection()
            .getDocuments()
            .documents
            .map { doc in
                return Account(doc: doc)
            }
        return accountList
    }
    
    public func getAccount(accountType: String) -> [Account]{
        var accountList = [Account]()
        
        getAccountCollection()
            .whereField(ConstantUtils.accountKeyAccountType, isEqualTo: accountType)
            .getDocuments { snapshot, error in
                if error == nil {
                    if let snapshot = snapshot {
                        accountList = snapshot.documents.map { doc in
                            return Account(doc: doc)
                        }
                    }
                } else {
                    
                }
            }
        return accountList
    }
    
    public func addTransaction(accountID: String, account: Account) {
        var balanceChange = 0.0
        if(account.accountType == "Saving" || account.accountType == "Credit Card" || account.accountType == "Loan" || account.accountType == "Other") {
            balanceChange = account.currentBalance
        } else {
            balanceChange = account.totalShares
        }
        
        let newTransaction = AccountTransaction(timestamp: Date(), balanceChange: balanceChange)
        
        do {
            let documentID = try getAccountCollection()
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .addDocument(from: newTransaction).documentID
            
            print("New Account transaction added : " + documentID)
        } catch {
            print(error)
        }
    }
    
    public func getAccountTransactionList(id: String) async throws -> [AccountTransaction] {
        var accountTransactionList = [AccountTransaction]()
        accountTransactionList = try await getAccountCollection()
            .document(id)
            .collection(ConstantUtils.accountTransactionCollectionName)
            .order(by: ConstantUtils.accountTransactionKeytimestamp, descending: true)
            .getDocuments()
            .documents
            .map { doc in
                return AccountTransaction(id: doc.documentID,
                                          timestamp: (doc[ConstantUtils.accountTransactionKeytimestamp] as? Timestamp)?.dateValue() ?? Date(),
                                          balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0)
            }
        
        return accountTransactionList
    }
    
    public func getLastTwoAccountTransactionList(id: String) async throws -> [AccountTransaction] {
        var accountTransactionList = [AccountTransaction]()
        accountTransactionList = try await getAccountCollection()
            .document(id)
            .collection(ConstantUtils.accountTransactionCollectionName)
            .order(by: ConstantUtils.accountTransactionKeytimestamp, descending: true)
            .limit(to: 2)
            .getDocuments()
            .documents
            .map { doc in
                return AccountTransaction(id: doc.documentID,
                                          timestamp: (doc[ConstantUtils.accountTransactionKeytimestamp] as? Timestamp)?.dateValue() ?? Date(),
                                          balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0)
            }
        
        return accountTransactionList
    }
    
    
    public func fetchTotalBalance() async throws -> BalanceModel {
        
        var accounts: [Account] = []
        
        accounts = try await getAccountList()
        
        return try await withThrowingTaskGroup(of: BalanceModel.self) { group in
            
            var balance = BalanceModel(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
            
            for account in accounts {
                if(!(account.accountType == "Saving" || account.accountType == "Credit Card" || account.accountType == "Loan" || account.accountType == "Other")) {
                    group.addTask {
                        var balanceModel = BalanceModel()
                        if(account.currency != SettingsController().getDefaultCurrency().code) {
                            let financeDetailModel = try await self.financeController.getSymbolDetails(accountCurrency: account.currency)
                            balanceModel.currentValue = financeDetailModel.regularMarketPrice ?? 0.0
                            balanceModel.previousDayValue = financeDetailModel.chartPreviousClose ?? 0.0
                        }
                        let financeDetailModel = try await self.financeController.getSymbolDetails(symbol: account.symbol)
                        balanceModel.currentValue = balanceModel.currentValue * account.totalShares * (financeDetailModel.regularMarketPrice ?? 1.0)
                        balanceModel.previousDayValue = balanceModel.previousDayValue * account.totalShares * (financeDetailModel.chartPreviousClose ?? 1.0)
                        balanceModel.oneDayChange = balanceModel.currentValue - balanceModel.previousDayValue
                        return balanceModel
                    }
                } else {
                    group.addTask {
                        var balanceModel = BalanceModel()
                        if(account.currency != SettingsController().getDefaultCurrency().code) {
                            let financeDetailModel =  try await self.financeController.getSymbolDetails(accountCurrency: account.currency)
                            balanceModel.currentValue = financeDetailModel.regularMarketPrice ?? 0.0
                            balanceModel.previousDayValue = financeDetailModel.chartPreviousClose ?? 0.0
                        }
                        let accountTransaction = try await self.getLastTwoAccountTransactionList(id: account.id!)
                        balanceModel.currentValue = balanceModel.currentValue * account.currentBalance
                        if(accountTransaction.count > 1) {
                            balanceModel.previousDayValue = balanceModel.previousDayValue * accountTransaction[1].balanceChange
                        } else {
                            balanceModel.previousDayValue = balanceModel.previousDayValue * account.currentBalance
                        }
                        balanceModel.oneDayChange = balanceModel.currentValue - balanceModel.previousDayValue
                        return balanceModel
                    }
                }
            }
            
            for try await taskResult in group {
                balance.currentValue += taskResult.currentValue
                balance.oneDayChange += taskResult.oneDayChange
            }
            
            return balance
            
        }
    }
    
    
}
