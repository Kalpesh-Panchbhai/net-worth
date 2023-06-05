//
//  AccountTransactionController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/06/23.
//

import Foundation
import FirebaseFirestore

class AccountTransactionController {
    
    public func addTransaction(accountID: String, accountTransaction: AccountTransaction) async {
        do {
            let documentID = try AccountController().getAccountCollection()
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .addDocument(from: accountTransaction).documentID
            
            print("New Account transaction added : " + documentID)
        } catch {
            print(error)
        }
    }
    
    public func addTransaction(accountID: String, account: Account, timestamp: Date, operation: String) async {
        let accountTransactionsList = await getAccountTransactionList(accountID: accountID)
        if(accountTransactionsList.count > 0) {
            if(accountTransactionsList.last!.timestamp > timestamp) {
                // Transaction Start
                var start = accountTransactionsList.last!
                start.balanceChange = start.currentBalance - account.currentBalance
                
                updateAccountTransaction(accountTransaction: start, accountID: accountID)
                
                let newTransaction = AccountTransaction(timestamp: timestamp, balanceChange: account.currentBalance, currentBalance: account.currentBalance)
                
                do {
                    let documentID = try AccountController().getAccountCollection()
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
                        let documentID = try AccountController().getAccountCollection()
                            .document(accountID)
                            .collection(ConstantUtils.accountTransactionCollectionName)
                            .addDocument(from: newTransaction).documentID
                        
                        print("New Account transaction added : " + documentID)
                    } catch {
                        print(error)
                    }
                    AccountController().updateAccount(account: updatedAccount)
                } else {
                    let balanceChange = account.currentBalance - accountTransactionsList.first!.currentBalance
                    let newTransaction = AccountTransaction(timestamp: timestamp, balanceChange: balanceChange, currentBalance: account.currentBalance)
                    
                    do {
                        let documentID = try AccountController().getAccountCollection()
                            .document(accountID)
                            .collection(ConstantUtils.accountTransactionCollectionName)
                            .addDocument(from: newTransaction).documentID
                        
                        print("New Account transaction added : " + documentID)
                    } catch {
                        print(error)
                    }
                    AccountController().updateAccount(account: account)
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
                    let documentID = try AccountController().getAccountCollection()
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
                let documentID = try AccountController().getAccountCollection()
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
            try AccountController().getAccountCollection()
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .document(accountTransaction.id!)
                .setData(from: accountTransaction, merge: true)
        } catch {
            print(error)
        }
    }
    
    public func getAccountTransactionList(accountID: String) async -> [AccountTransaction] {
        var accountTransactionList = [AccountTransaction]()
        do {
            accountTransactionList = try await AccountController().getAccountCollection()
                .document(accountID)
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
        } catch {
            print(error)
        }
        return accountTransactionList
    }
    
    public func getAccountTransactionListWithRange(accountID: String, range: String) async -> [AccountTransaction] {
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
            do {
                accountTransactionList = try await AccountController().getAccountCollection()
                    .document(accountID)
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
            } catch {
                print(error)
            }
            return accountTransactionList
        }
        var accountTransactionList = [AccountTransaction]()
        do {
            accountTransactionList = try await AccountController().getAccountCollection()
                .document(accountID)
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
        } catch {
            print(error)
        }
        return accountTransactionList
    }
    
    public func getAccountLastTransactionBelowRange(accountID: String, range: String) async -> [AccountTransaction] {
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
        do {
            accountTransactionList = try await AccountController().getAccountCollection()
                .document(accountID)
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
        } catch {
            print(error)
        }
        return accountTransactionList
    }
    
    public func getLastTwoAccountTransactionList(accountID: String) async -> [AccountTransaction] {
        var accountTransactionList = [AccountTransaction]()
        do {
            accountTransactionList = try await AccountController()
                .getAccountCollection()
                .document(accountID)
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
        } catch {
            print(error)
        }
        return accountTransactionList
    }
    
    public func deleteAccountTransaction(accountID: String, id: String) async {
        do {
            try await AccountController().getAccountCollection()
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .document(id)
                .delete()
        } catch {
            print(error)
        }
    }
    
}
