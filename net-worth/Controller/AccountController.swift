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
    private var watchController = WatchController()
    
    private func getAccountCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
    }
    
    public func addAccount(newAccount: Account) -> String {
        do {
            let accountID = try getAccountCollection()
                .addDocument(from: newAccount).documentID
            addTransaction(accountID: accountID, account: newAccount)
            return accountID
        } catch {
            print(error)
        }
        return ""
    }
    
    public func deleteAccount(account: Account) async throws {
        let watchList = try await watchController.getAllWatchList()
        watchList.forEach { watch in
            if(watch.accountID.contains(account.id!)) {
                watchController.deleteAccountFromWatchList(watchList: watch, accountID: account.id!)
            }
        }
        CommonController.delete(collection: getAccountCollection().document(account.id!).collection(ConstantUtils.accountTransactionCollectionName))
        try await getAccountCollection().document(account.id!).delete()
    }
    
    public func deleteAccounts() async throws {
        let accountList = try await getAccountList()
        for account in accountList {
            try await deleteAccount(account: account)
        }
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
            .order(by: ConstantUtils.accountKeyAccountName)
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
        balanceChange = account.currentBalance
        
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
    
    public func getAccountTransactionListWithRange(id: String, range: String) async throws -> [AccountTransaction] {
        var date = Timestamp()
        if(range.elementsEqual("1M")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-2592000))
        } else if(range.elementsEqual("3M")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-7776000))
        } else if(range.elementsEqual("6M")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-15552000))
        } else if(range.elementsEqual("1Y")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-31104000))
        } else if(range.elementsEqual("2Y")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-62208000))
        } else if(range.elementsEqual("5Y")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-155520000))
        } else if(range.elementsEqual("All")) {
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
        var accountTransactionList = [AccountTransaction]()
        accountTransactionList = try await getAccountCollection()
            .document(id)
            .collection(ConstantUtils.accountTransactionCollectionName)
            .order(by: ConstantUtils.accountTransactionKeytimestamp, descending: true)
            .whereField(ConstantUtils.accountTransactionKeytimestamp, isGreaterThanOrEqualTo: date)
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
    
    
    public func fetchTotalBalance(accountList: [Account]) async throws -> BalanceModel {
        var accounts: [Account] = []
        if(accountList.isEmpty) {
            accounts = try await getAccountList()
        } else {
            accounts = accountList
        }
        
        return try await withThrowingTaskGroup(of: BalanceModel.self) { group in
            
            var balance = BalanceModel(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
            
            for account in accounts {
                group.addTask {
                    var balanceModel = BalanceModel()
                    if(account.currency != SettingsController().getDefaultCurrency().code) {
                        let financeDetailModel =  try await FinanceController().getSymbolDetails(accountCurrency: account.currency)
                        balanceModel.currentValue = financeDetailModel.regularMarketPrice ?? 0.0
                        balanceModel.previousDayValue = financeDetailModel.chartPreviousClose ?? 0.0
                    }
                    let accountTransaction = try await self.getLastTwoAccountTransactionList(id: account.id!)
                    balanceModel.currentValue = balanceModel.currentValue * account.currentBalance
                    if(accountTransaction.count > 1 && accountTransaction[0].timestamp.timeIntervalSince(Date()) > -86400) {
                        balanceModel.previousDayValue = balanceModel.previousDayValue * accountTransaction[1].balanceChange
                    } else if(accountTransaction.count == 1 && accountTransaction[0].timestamp.timeIntervalSince(Date()) > -86400) {
                        balanceModel.currentValue = balanceModel.previousDayValue * accountTransaction[0].balanceChange
                        balanceModel.previousDayValue = 0
                    } else {
                        balanceModel.previousDayValue = balanceModel.previousDayValue * account.currentBalance
                    }
                    balanceModel.oneDayChange = balanceModel.currentValue - balanceModel.previousDayValue
                    return balanceModel
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
