//
//  ItemViewController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import Foundation
import SwiftUI
import FirebaseFirestore

//MARK: Account
class AccountController {
    
    var notificationController = NotificationController()
    var watchController = WatchController()
    var accountTransactionController = AccountTransactionController()
    
    public func getAccountCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
    }
    
    public func addAccount(newAccount: Account) async -> String {
        do {
            let accountID = try getAccountCollection()
                .addDocument(from: newAccount).documentID
            return accountID
        } catch {
            print(error)
        }
        return ""
    }
    
    public func addAccount(newAccount: Account, accountOpenedDate: Date) async -> String {
        do {
            let accountID = try getAccountCollection()
                .addDocument(from: newAccount).documentID
            await accountTransactionController.addTransaction(accountID: accountID, account: newAccount, timestamp: accountOpenedDate)
            return accountID
        } catch {
            print(error)
        }
        return ""
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
    
    public func getAccount(id: String) async -> Account {
        var account = Account()
        do {
            account = try await getAccountCollection()
                .document(id)
                .getDocument()
                .data(as: Account.self)
        } catch {
            print(error)
        }
        return account
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
    
    public func getAccountList() async -> [Account] {
        var accountList = [Account]()
        do {
            accountList = try await getAccountCollection()
                .order(by: ConstantUtils.accountKeyAccountName)
                .getDocuments()
                .documents
                .map { doc in
                    return Account(doc: doc)
                }
        } catch {
            print(error)
        }
        return accountList
    }
    
    public func fetchTotalBalance(accountList: [Account]) async -> Balance {
        var accounts: [Account] = []
        if(accountList.isEmpty) {
            accounts = await getAccountList()
        } else {
            accounts = accountList
        }
        do {
            return try await withThrowingTaskGroup(of: Balance.self) { group in
                
                var balance = Balance(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
                
                for account in accounts {
                    group.addTask {
                        var balance = Balance()
                        if(account.currency != SettingsController().getDefaultCurrency().code) {
                            let financeDetailModel = await FinanceController().getSymbolDetails(accountCurrency: account.currency)
                            balance.currentValue = financeDetailModel.regularMarketPrice ?? 0.0
                            balance.previousDayValue = financeDetailModel.chartPreviousClose ?? 0.0
                        }
                        let accountTransaction = await self.accountTransactionController.getLastTwoAccountTransactionList(id: account.id!)
                        balance.currentValue = balance.currentValue * account.currentBalance
                        if(accountTransaction.count > 1 && accountTransaction[0].timestamp.timeIntervalSince(Date()) > -86400) {
                            balance.previousDayValue = balance.previousDayValue * accountTransaction[1].currentBalance
                        } else if(accountTransaction.count == 1 && accountTransaction[0].timestamp.timeIntervalSince(Date()) > -86400) {
                            balance.currentValue = balance.previousDayValue * accountTransaction[0].currentBalance
                            balance.previousDayValue = 0
                        } else {
                            balance.previousDayValue = balance.previousDayValue * account.currentBalance
                        }
                        balance.oneDayChange = balance.currentValue - balance.previousDayValue
                        return balance
                    }
                }
                
                for try await taskResult in group {
                    balance.currentValue += taskResult.currentValue
                    balance.oneDayChange += taskResult.oneDayChange
                }
                
                return balance
                
            }
        } catch {
            print(error)
        }
        return Balance(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
    }
    
    public func deleteAccount(account: Account) async {
        let watchList = await watchController.getAllWatchList()
        watchList.forEach { watch in
            if(watch.accountID.contains(account.id!)) {
                watchController.deleteAccountFromWatchList(watchList: watch, accountID: account.id!)
            }
        }
        CommonController.delete(collection: getAccountCollection().document(account.id!).collection(ConstantUtils.accountTransactionCollectionName))
        do {
            try await getAccountCollection().document(account.id!).delete()
        } catch {
            print(error)
        }
    }
    
    public func deleteAccounts() async {
        let accountList = await getAccountList()
        for account in accountList {
            await deleteAccount(account: account)
        }
    }
}
