//
//  BrokerAccountController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 30/11/23.
//

import Foundation
import Firebase
import FirebaseFirestore

class BrokerAccountController {
    
    public func getAccountCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
    }
    
    public func addAccountInBroker(brokerID: String, accountBroker: AccountBroker) {
        do {
            let accountID = try getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .addDocument(from: accountBroker).documentID
            
            print("New Account added in Broker : " + accountID)
            
            let accountTransaction = AccountTransaction(timestamp: accountBroker.timestamp, balanceChange: accountBroker.currentUnit, currentBalance: accountBroker.currentUnit)
            addTransactionInBrokerAccount(brokerID: brokerID, accountID: accountID, accountTransaction: accountTransaction)
            
        } catch {
            print(error)
        }
    }
    
    public func updateAccountInBroker(brokerID: String, accountBroker: AccountBroker) {
        do {
            try getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .document(accountBroker.id!)
                .setData(from: accountBroker, merge: true)
            
        } catch {
            print(error)
        }
    }
    
    public func addTransactionInBrokerAccount(brokerID: String, accountID: String, accountTransaction: AccountTransaction) {
        do {
            let documentID = try getAccountCollection()
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
    
    public func getAccountInBrokerList(brokerID: String) async -> [AccountBroker] {
        var accountBrokerList = [AccountBroker]()
        do {
            accountBrokerList = try await AccountController()
                .getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .order(by: ConstantUtils.accountBrokerKeyName, descending: false)
                .getDocuments()
                .documents
                .map { doc in
                    return AccountBroker(id: doc.documentID,
                                         timestamp: (doc[ConstantUtils.accountBrokerKeyTimeStamp] as? Timestamp)?.dateValue() ?? Date(),
                                         symbol: doc[ConstantUtils.accountBrokerKeySymbol] as? String ?? "",
                                         name: doc[ConstantUtils.accountBrokerKeyName] as? String ?? "",
                                         currentUnit: doc[ConstantUtils.accountBrokerKeyCurrentUnit] as? Double ?? 0.0)
                }
        } catch {
            print(error)
        }
        return accountBrokerList
    }
    
    public func getAccountTransactionsInBrokerAccountList(brokerID: String, accountID: String) async -> [AccountTransaction] {
        var accountTransactionList = [AccountTransaction]()
        do {
            accountTransactionList = try await AccountController()
                .getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
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
    
    public func getBrokerAccountCurrentBalance(accountBroker: AccountBroker) async -> Balance {
        var balance = Balance()
        let financeDetailModel = await FinanceController().getSymbolDetail(symbol: accountBroker.symbol)
        balance.currentValue = (financeDetailModel.regularMarketPrice ?? 0.0) * accountBroker.currentUnit
        balance.previousDayValue = (financeDetailModel.chartPreviousClose ?? 0.0) * accountBroker.currentUnit
        
        if(financeDetailModel.currency != SettingsController().getDefaultCurrency().code) {
            let currencyModel = await FinanceController().getSymbolDetails(accountCurrency: financeDetailModel.currency!)
            balance.currentValue = balance.currentValue * currencyModel.regularMarketPrice!
            balance.previousDayValue = balance.previousDayValue * currencyModel.chartPreviousClose!
        }
        
        return balance
    }
    
    public func addBrokerAccountTransaction(brokerID: String, accountBroker: AccountBroker, timeStamp: Date) async {
        
        let accountTransactionList = await getAccountTransactionsInBrokerAccountList(brokerID: brokerID, accountID: accountBroker.id!)
        let balanceChange = accountBroker.currentUnit - accountTransactionList.first!.currentBalance
        let accountTransaction = AccountTransaction(timestamp: timeStamp, balanceChange: balanceChange, currentBalance: accountBroker.currentUnit)
        do {
            try AccountController()
                .getAccountCollection()
                .document(brokerID)
                .collection(ConstantUtils.accountBrokerCollectionName)
                .document(accountBroker.id!)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .addDocument(from: accountTransaction)
            
            var updatedBrokerAccount = accountBroker
            updatedBrokerAccount.timestamp = timeStamp
            
            updateAccountInBroker(brokerID: brokerID, accountBroker: updatedBrokerAccount)
        } catch {
            print(error)
        }
    }
    
}
