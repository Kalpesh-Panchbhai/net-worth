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
    
    private var notificationController = NotificationController()
    private var watchController = WatchController()
    
    private func getAccountCollection() -> CollectionReference {
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
            try await addTransaction(accountID: accountID, account: newAccount, timestamp: accountOpenedDate)
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
    
    public func getAccount(id: String) async throws -> Account {
        var account = Account()
        
        account = try await getAccountCollection()
            .document(id)
            .getDocument()
            .data(as: Account.self)
        
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
    
    public func fetchTotalBalance(accountList: [Account]) async throws -> Balance {
        var accounts: [Account] = []
        if(accountList.isEmpty) {
            accounts = try await getAccountList()
        } else {
            accounts = accountList
        }
        
        return try await withThrowingTaskGroup(of: Balance.self) { group in
            
            var balance = Balance(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
            
            for account in accounts {
                group.addTask {
                    var balance = Balance()
                    if(account.currency != SettingsController().getDefaultCurrency().code) {
                        let financeDetailModel =  try await FinanceController().getSymbolDetails(accountCurrency: account.currency)
                        balance.currentValue = financeDetailModel.regularMarketPrice ?? 0.0
                        balance.previousDayValue = financeDetailModel.chartPreviousClose ?? 0.0
                    }
                    let accountTransaction = try await self.getLastTwoAccountTransactionList(id: account.id!)
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
}

//MARK: Account Transaction
extension AccountController {
    
    public func addTransaction(accountID: String, account: Account, timestamp: Date) async throws {
        let newTransaction = AccountTransaction(timestamp: timestamp, balanceChange: account.currentBalance, currentBalance: account.currentBalance)
        
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
    
    public func addTransaction(accountID: String, accountTransaction: AccountTransaction) async throws {
        do {
            let documentID = try getAccountCollection()
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .addDocument(from: accountTransaction).documentID
            
            print("New Account transaction added : " + documentID)
        } catch {
            print(error)
        }
    }
    
    public func addTransaction(accountID: String, account: Account, timestamp: Date, operation: String) async throws {
        let accountTransactionsList = try await getAccountTransactionList(id: accountID)
        if(accountTransactionsList.count > 0) {
            if(accountTransactionsList.last!.timestamp > timestamp) {
                // Transaction Start
                var start = accountTransactionsList.last!
                start.balanceChange = start.currentBalance - account.currentBalance
                
                updateAccountTransaction(accountTransaction: start, accountID: accountID)
                
                let newTransaction = AccountTransaction(timestamp: timestamp, balanceChange: account.currentBalance, currentBalance: account.currentBalance)
                
                do {
                    let documentID = try getAccountCollection()
                        .document(accountID)
                        .collection(ConstantUtils.accountTransactionCollectionName)
                        .addDocument(from: newTransaction).documentID
                    
                    print("New Account transaction added : " + documentID)
                } catch {
                    print(error)
                }
                
            } else if(accountTransactionsList.first!.timestamp < timestamp) {
                // Transaction Last
                if(operation.elementsEqual("Add")) {
                    let currentBalance = account.currentBalance + accountTransactionsList.first!.currentBalance
                    let balanceChange = currentBalance - accountTransactionsList.first!.currentBalance
                    var updatedAccount = account
                    updatedAccount.currentBalance = currentBalance
                    let newTransaction = AccountTransaction(timestamp: timestamp, balanceChange: balanceChange, currentBalance: currentBalance)
                    
                    do {
                        let documentID = try getAccountCollection()
                            .document(accountID)
                            .collection(ConstantUtils.accountTransactionCollectionName)
                            .addDocument(from: newTransaction).documentID
                        
                        print("New Account transaction added : " + documentID)
                    } catch {
                        print(error)
                    }
                    updateAccount(account: updatedAccount)
                } else {
                    let balanceChange = account.currentBalance - accountTransactionsList.first!.currentBalance
                    let newTransaction = AccountTransaction(timestamp: timestamp, balanceChange: balanceChange, currentBalance: account.currentBalance)
                    
                    do {
                        let documentID = try getAccountCollection()
                            .document(accountID)
                            .collection(ConstantUtils.accountTransactionCollectionName)
                            .addDocument(from: newTransaction).documentID
                        
                        print("New Account transaction added : " + documentID)
                    } catch {
                        print(error)
                    }
                    updateAccount(account: account)
                }
            } else {
                var first = AccountTransaction(timestamp: Date(), balanceChange: 0.0, currentBalance: 0.0)
                var last = AccountTransaction(timestamp: Date(), balanceChange: 0.0, currentBalance: 0.0)
                for i in 0..<accountTransactionsList.count - 1 {
                    if(accountTransactionsList[i].timestamp > timestamp && accountTransactionsList[i + 1].timestamp < timestamp) {
                        first = accountTransactionsList[i]
                        last = accountTransactionsList[i + 1]
                        break
                    }
                }
                first.balanceChange = first.currentBalance - account.currentBalance
                updateAccountTransaction(accountTransaction: first, accountID: accountID)
                let balanceChange = account.currentBalance - last.currentBalance
                let newTransaction = AccountTransaction(timestamp: timestamp, balanceChange: balanceChange, currentBalance: account.currentBalance)
                
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
        }
    }
    
    public func addLoanAccountEMITransaction(account: Account, emiDate: Int, accountOpenedDate: Date, monthlyEmiAmount: Double) {
        var currentBalance = account.currentBalance
        var monthlyEmiAmount = monthlyEmiAmount
        var calendarDate = Calendar.current.dateComponents([.year, .month, .day], from: accountOpenedDate)
        calendarDate.day = emiDate
        while(currentBalance<0.0) {
            if((currentBalance + monthlyEmiAmount) > 0) {
                monthlyEmiAmount = currentBalance * -1.0
                currentBalance = 0.0
            } else {
                currentBalance = currentBalance + monthlyEmiAmount
            }
            calendarDate.month!+=1
            if(calendarDate.month! > 12) {
                calendarDate.month!=1
                calendarDate.year!+=1
            }
            let paymentDate = Calendar.current.date(from: calendarDate)
            let newTransaction = AccountTransaction(timestamp: paymentDate!, balanceChange: monthlyEmiAmount, currentBalance: currentBalance, paid: false)
            
            do {
                let documentID = try getAccountCollection()
                    .document(account.id!)
                    .collection(ConstantUtils.accountTransactionCollectionName)
                    .addDocument(from: newTransaction).documentID
                
                print("New Account transaction added : " + documentID)
            } catch {
                print(error)
            }
        }
    }
    
    public func updateAccountTransaction(accountTransaction: AccountTransaction, accountID: String) {
        do {
            try getAccountCollection()
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .document(accountTransaction.id!)
                .setData(from: accountTransaction, merge: true)
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
                                          balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0,
                                          currentBalance: doc[ConstantUtils.accountTransactionKeyCurrentBalance] as? Double ?? 0.0,
                                          paid: doc[ConstantUtils.accountTransactionKeyPaid] as? Bool ?? true)
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
                                              balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0,
                                              currentBalance: doc[ConstantUtils.accountTransactionKeyCurrentBalance] as? Double ?? 0.0,
                                              paid: doc[ConstantUtils.accountTransactionKeyPaid] as? Bool ?? true)
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
                                          balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0,
                                          currentBalance: doc[ConstantUtils.accountTransactionKeyCurrentBalance] as? Double ?? 0.0,
                                          paid: doc[ConstantUtils.accountTransactionKeyPaid] as? Bool ?? true)
            }
        
        return accountTransactionList
    }
    
    public func getAccountLastTransactionBelowRange(id: String, range: String) async throws -> [AccountTransaction] {
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
        }
        var accountTransactionList = [AccountTransaction]()
        accountTransactionList = try await getAccountCollection()
            .document(id)
            .collection(ConstantUtils.accountTransactionCollectionName)
            .order(by: ConstantUtils.accountTransactionKeytimestamp, descending: true)
            .whereField(ConstantUtils.accountTransactionKeytimestamp, isLessThan: date)
            .getDocuments()
            .documents
            .map { doc in
                return AccountTransaction(id: doc.documentID,
                                          timestamp: (doc[ConstantUtils.accountTransactionKeytimestamp] as? Timestamp)?.dateValue() ?? Date(),
                                          balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0,
                                          currentBalance: doc[ConstantUtils.accountTransactionKeyCurrentBalance] as? Double ?? 0.0,
                                          paid: doc[ConstantUtils.accountTransactionKeyPaid] as? Bool ?? true)
            }
        
        return accountTransactionList
    }
    
    public func getLastTwoAccountTransactionList(id: String) async throws -> [AccountTransaction] {
        var accountTransactionList = [AccountTransaction]()
        accountTransactionList = try await getAccountCollection()
            .document(id)
            .collection(ConstantUtils.accountTransactionCollectionName)
            .whereField(ConstantUtils.accountTransactionKeyPaid, isEqualTo: true)
            .order(by: ConstantUtils.accountTransactionKeytimestamp, descending: true)
            .limit(to: 2)
            .getDocuments()
            .documents
            .map { doc in
                return AccountTransaction(id: doc.documentID,
                                          timestamp: (doc[ConstantUtils.accountTransactionKeytimestamp] as? Timestamp)?.dateValue() ?? Date(),
                                          balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0,
                                          currentBalance: doc[ConstantUtils.accountTransactionKeyCurrentBalance] as? Double ?? 0.0,
                                          paid: doc[ConstantUtils.accountTransactionKeyPaid] as? Bool ?? true)
            }
        
        return accountTransactionList
    }
    
    public func deleteAccountTransaction(accountID: String, accountTransactionID: String) async throws {
        try await getAccountCollection()
            .document(accountID)
            .collection(ConstantUtils.accountTransactionCollectionName)
            .document(accountTransactionID)
            .delete()
    }
}
