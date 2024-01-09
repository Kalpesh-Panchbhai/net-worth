//
//  AccountInBrokerController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 30/11/23.
//

import Foundation
import Firebase
import FirebaseFirestore

class AccountInBrokerController {
    
    private var accountController = AccountController()
    
    public func fetchLastestAccountListInBroker(brokerID: String) async -> [AccountInBroker] {
        var accountBrokerList = [AccountInBroker]()
        do {
            let lastUpdatedDateTime = ApplicationData.shared.data.accountDataListUpdatedDate
            
            accountBrokerList = try await accountController
                .getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .whereField(ConstantUtils.accountBrokerKeyLastUpdated, isGreaterThanOrEqualTo: lastUpdatedDateTime)
                .getDocuments()
                .documents
                .map { doc in
                    return AccountInBroker(id: doc.documentID,
                                           timestamp: (doc[ConstantUtils.accountBrokerKeyTimeStamp] as? Timestamp)?.dateValue() ?? Date(),
                                           symbol: doc[ConstantUtils.accountBrokerKeySymbol] as? String ?? "",
                                           name: doc[ConstantUtils.accountBrokerKeyName] as? String ?? "",
                                           currentUnit: doc[ConstantUtils.accountBrokerKeyCurrentUnit] as? Double ?? 0.0,
                                           lastUpdated: (doc[ConstantUtils.accountBrokerKeyLastUpdated] as? Timestamp)?.dateValue() ?? Date(),
                                           deleted: doc[ConstantUtils.accountBrokerKeyDeleted] as? Bool ?? false)
                }
        } catch {
            print(error)
        }
        return accountBrokerList
    }
    
    public func fetchLastestAccountTransactionListInAccountInBroker(brokerID: String, accountID: String) async -> [AccountTransaction] {
        var accountTransactionList = [AccountTransaction]()
        do {
            let lastUpdatedDateTime = ApplicationData.shared.data.accountDataListUpdatedDate
            
            accountTransactionList = try await accountController
                .getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .whereField(ConstantUtils.accountTransactionKeyCreatedDate, isGreaterThanOrEqualTo: lastUpdatedDateTime)
                .getDocuments()
                .documents
                .map { doc in
                    return AccountTransaction(id: doc.documentID,
                                              timestamp: (doc[ConstantUtils.accountTransactionKeytimestamp] as? Timestamp)?.dateValue() ?? Date(),
                                              balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0,
                                              currentBalance: doc[ConstantUtils.accountTransactionKeyCurrentBalance] as? Double ?? 0.0,
                                              paid: doc[ConstantUtils.accountTransactionKeyPaid] as? Bool ?? true,
                                              createdDate: (doc[ConstantUtils.accountTransactionKeyCreatedDate] as? Timestamp)?.dateValue() ?? Date(),
                                              deleted: doc[ConstantUtils.accountTransactionKeyDeleted] as? Bool ?? false)
                }
        } catch {
            print(error)
        }
        return accountTransactionList
    }
    
    public func addAccountInBroker(brokerID: String, accountInBroker: AccountInBroker) async {
        do {
            let accountID = try accountController.getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .addDocument(from: accountInBroker).documentID
            
            print("New Account added in Broker : " + accountID)
            
            let accountTransaction = AccountTransaction(timestamp: accountInBroker.timestamp, balanceChange: accountInBroker.currentUnit, currentBalance: accountInBroker.currentUnit, createdDate: accountInBroker.lastUpdated)
            addTransactionInAccountInBroker(brokerID: brokerID, accountID: accountID, accountTransaction: accountTransaction)
            
            var updatedAccount = ApplicationData.shared.data.accountDataList.first(where: {
                return $0.account.id!.elementsEqual(brokerID)
            })!.account
            updatedAccount.lastUpdated = accountInBroker.lastUpdated
            
            await AccountController().updateAccount(account: updatedAccount)
        } catch {
            print(error)
        }
    }
    
    public func updateAccountInBroker(brokerID: String, accountBroker: AccountInBroker) async {
        do {
            let id = accountBroker.id!
            var updatedAccountBroker = accountBroker
            updatedAccountBroker.id = nil
            try accountController.getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .document(id)
                .setData(from: updatedAccountBroker, merge: true)
            
            var updatedAccount = ApplicationData.shared.data.accountDataList.first(where: {
                return $0.account.id!.elementsEqual(brokerID)
            })!.account
            updatedAccount.lastUpdated = accountBroker.lastUpdated
            await AccountController().updateAccount(account: updatedAccount)
            
        } catch {
            print(error)
        }
    }
    
    public func addTransactionInAccountInBroker(brokerID: String, accountID: String, accountTransaction: AccountTransaction) {
        do {
            let documentID = try accountController.getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .addDocument(from: accountTransaction).documentID
            
            print("New Transaction added in Account Broker : " + documentID)
            
        } catch {
            print(error)
        }
    }
    
    public func getAccountListInBroker(brokerID: String) -> [AccountInBroker] {
        let accountBrokerList = ApplicationData.shared.data.accountDataList.first(where: {
            return $0.account.id!.elementsEqual(brokerID)
        }).map {
            return $0.accountInBroker
        }.map {
            return $0.map {
                return AccountInBroker(id: $0.accountInBroker.id!,
                                       timestamp: $0.accountInBroker.timestamp,
                                       symbol: $0.accountInBroker.symbol,
                                       name: $0.accountInBroker.name,
                                       currentUnit: $0.accountInBroker.currentUnit)
            }
        } ?? [AccountInBroker]()
        
        return accountBrokerList
    }
    
    public func getAccountInBroker(brokerID: String, accountID: String) -> AccountInBroker {
        let accountBroker = ApplicationData.shared.data.accountDataList.filter {
            return $0.account.id == brokerID
        }.first!.accountInBroker.first(where: {
            return $0.accountInBroker.id == accountID
        })?.accountInBroker ?? AccountInBroker()
        return accountBroker
    }
    
    public func getAccountTransactionListInAccountInBroker(brokerID: String, accountID: String) -> [AccountTransaction] {
        let accountTransactionList = ApplicationData.shared.data.accountDataList.filter {
            return $0.account.id == brokerID
        }.first!.accountInBroker.first(where: {
            return $0.accountInBroker.id == accountID
        })?.accountTransaction ?? [AccountTransaction]()
        return accountTransactionList
    }
    
    public func getAccountTransactionListInAccountInBrokerWithRange(brokerID: String, accountID: String, range: String) -> [AccountTransaction] {
        var date = Date()
        if(range.elementsEqual(ConstantUtils.oneMonthRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-2592000)).dateValue()
        } else if(range.elementsEqual(ConstantUtils.threeMonthRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-7776000)).dateValue()
        } else if(range.elementsEqual(ConstantUtils.sixMonthRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-15552000)).dateValue()
        } else if(range.elementsEqual(ConstantUtils.oneYearRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-31104000)).dateValue()
        } else if(range.elementsEqual(ConstantUtils.twoYearRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-62208000)).dateValue()
        } else if(range.elementsEqual(ConstantUtils.fiveYearRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-155520000)).dateValue()
        }
        
        let accountTransactionList = ApplicationData.shared.data.accountDataList.filter {
            return $0.account.id == brokerID
        }.first!.accountInBroker.filter {
            return $0.accountInBroker.id == accountID
        }.first!.accountTransaction.filter {
            return $0.timestamp.removeTimeStamp() >= date.removeTimeStamp()
        }
        return accountTransactionList
    }
    
    public func getAccountTransactionListInAccountInBrokerBelowRange(brokerID: String, accountID: String, range: String) -> [AccountTransaction] {
        var date = Date()
        if(range.elementsEqual(ConstantUtils.oneMonthRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-2592000)).dateValue()
        } else if(range.elementsEqual(ConstantUtils.threeMonthRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-7776000)).dateValue()
        } else if(range.elementsEqual(ConstantUtils.sixMonthRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-15552000)).dateValue()
        } else if(range.elementsEqual(ConstantUtils.oneYearRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-31104000)).dateValue()
        } else if(range.elementsEqual(ConstantUtils.twoYearRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-62208000)).dateValue()
        } else if(range.elementsEqual(ConstantUtils.fiveYearRange)) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-155520000)).dateValue()
        }
        
        let accountTransactionList = ApplicationData.shared.data.accountDataList.filter {
            return $0.account.id == brokerID
        }.first!.accountInBroker.filter {
            return $0.accountInBroker.id == accountID
        }.first!.accountTransaction.filter {
            return $0.timestamp.removeTimeStamp() < date.removeTimeStamp()
        }
        return accountTransactionList
    }
    
    public func getCurrentBalanceOfAnAccountInBroker(accountBroker: AccountInBroker) async -> Balance {
        var currentBalance = Balance(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
        let financeDetailModel = await FinanceController().getSymbolDetail(symbol: accountBroker.symbol)
        currentBalance.currentValue = (financeDetailModel.regularMarketPrice ?? 0.0) * accountBroker.currentUnit
        currentBalance.previousDayValue = (financeDetailModel.chartPreviousClose ?? 0.0) * accountBroker.currentUnit
        
        if(financeDetailModel.currency != SettingsController().getDefaultCurrency().code) {
            let currencyModel = await FinanceController().getCurrencyDetail(accountCurrency: financeDetailModel.currency!)
            currentBalance.currentValue = currentBalance.currentValue * currencyModel.regularMarketPrice!
            currentBalance.previousDayValue = currentBalance.previousDayValue * currencyModel.chartPreviousClose!
        }
        currentBalance.oneDayChange = currentBalance.currentValue - currentBalance.previousDayValue
        return currentBalance
    }
    
    public func getCurrentBalanceOfAllAccountsInABroker(accountBrokerList: [AccountInBroker]) async -> Balance {
        var currentBalance = Balance(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
        for accountBroker in accountBrokerList {
            let accountBrokerCurrentBalance = await getCurrentBalanceOfAnAccountInBroker(accountBroker: accountBroker)
            currentBalance.currentValue = currentBalance.currentValue + accountBrokerCurrentBalance.currentValue
            currentBalance.previousDayValue = currentBalance.previousDayValue + accountBrokerCurrentBalance.previousDayValue
        }
        currentBalance.oneDayChange = currentBalance.currentValue - currentBalance.previousDayValue
        return currentBalance
    }
    
    public func addBrokerAccountTransaction(brokerID: String, accountBroker: AccountInBroker, timeStamp: Date) async {
        
        let accountTransactionList = getAccountTransactionListInAccountInBroker(brokerID: brokerID, accountID: accountBroker.id!)
        let lastCurrentBalance = accountTransactionList.count > 0 ? accountTransactionList.first!.currentBalance : 0.0
        let balanceChange = accountBroker.currentUnit - lastCurrentBalance
        let accountTransaction = AccountTransaction(timestamp: timeStamp, balanceChange: balanceChange, currentBalance: accountBroker.currentUnit, createdDate: accountBroker.lastUpdated)
        do {
            try accountController
                .getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .document(accountBroker.id!)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .addDocument(from: accountTransaction)
            
            var updatedBrokerAccount = accountBroker
            updatedBrokerAccount.timestamp = timeStamp
            
            await updateAccountInBroker(brokerID: brokerID, accountBroker: updatedBrokerAccount)
        } catch {
            print(error)
        }
    }
    
    public func deleteTransactionInAccountInBroker(brokerID: String, accountID: String) async {
        
        let currentDateTime = Date.now
        let accountTransactionList = getAccountTransactionListInAccountInBroker(brokerID: brokerID, accountID: accountID)
        let accountInBroker = getAccountInBroker(brokerID: brokerID, accountID: accountID)
        var lastAccountTransaction =  accountTransactionList.first!
        let transactionID = lastAccountTransaction.id!
        lastAccountTransaction.createdDate = currentDateTime
        lastAccountTransaction.deleted = true
        lastAccountTransaction.id = nil
        do {
            try accountController
                .getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .document(transactionID)
                .setData(from: lastAccountTransaction, merge: true)
            
            var updatedBrokerAccount = accountInBroker
            updatedBrokerAccount.lastUpdated = currentDateTime
            updatedBrokerAccount.currentUnit = accountTransactionList.count > 1 ? accountTransactionList[1].currentBalance : 0
            
            await updateAccountInBroker(brokerID: brokerID, accountBroker: updatedBrokerAccount)
        } catch {
            print(error)
        }
    }
    
    public func deleteAccountInBroker(brokerID: String, accountID: String) async {
        CommonController.delete(collection: accountController.getAccountCollection().document(brokerID).collection(ConstantUtils.accountBrokerCollectionName).document(accountID).collection(ConstantUtils.accountTransactionCollectionName))
        do {
            try await accountController.getAccountCollection().document(brokerID).collection(ConstantUtils.accountBrokerCollectionName).document(accountID).delete()
        } catch {
            print(error)
        }
    }
    
}
