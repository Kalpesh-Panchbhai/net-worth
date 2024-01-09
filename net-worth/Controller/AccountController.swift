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
    
    var watchController = WatchController()
    var accountTransactionController = AccountTransactionController()
    
    public func getAccountCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
    }
    
    public func fetchLastestAccountList() async -> [Account] {
        var accountList = [Account]()
        
        let date = ApplicationData.shared.data.accountDataListUpdatedDate
        do {
            accountList = try await getAccountCollection()
                .whereField(ConstantUtils.accountKeyLastUpdated, isGreaterThanOrEqualTo: date)
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
    
    public func addAccount(newAccount: Account) async -> String {
        do {
            let accountID = try getAccountCollection()
                .addDocument(from: newAccount).documentID
            
            await UserController().updateAccountUserData(updatedDate: newAccount.lastUpdated)
            
            await ApplicationData.loadData()
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
            if(newAccount.accountType != ConstantUtils.brokerAccountType) {
                let accountTransaction = AccountTransaction(timestamp: accountOpenedDate, balanceChange: newAccount.currentBalance, currentBalance: newAccount.currentBalance, createdDate: newAccount.lastUpdated)
                await accountTransactionController.addTransaction(accountID: accountID, accountTransaction: accountTransaction)
            }
            
            await UserController().updateAccountUserData(updatedDate: newAccount.lastUpdated)
            
            await ApplicationData.loadData()
            return accountID
        } catch {
            print(error)
        }
        return ""
    }
    
    public func getAccount(id: String) -> Account {
        let account = ApplicationData.shared.data.accountDataList.first(where: {
            $0.account.id!.elementsEqual(id)
        })
        
        return account.map {
            $0.account
        } ?? Account()
    }
    
    public func getAccountList(accountType: String) -> [Account]{
        let accountList = ApplicationData.shared.data.accountDataList.filter {
            $0.account.accountType.elementsEqual(accountType)
        }
        
        return accountList.map {
            $0.account
        }
    }
    
    public func getAccountList() -> [Account] {
        var accountList = [Account]()
        accountList = ApplicationData.shared.data.accountDataList.map {
            $0.account
        }
        return accountList.sorted(by: {
            $0.accountName < $1.accountName
        })
    }
    
    public func calculateTotalBalance(accountList: [Account]) async -> Balance {
        var accounts: [Account] = []
        if(accountList.isEmpty) {
            accounts = getAccountList()
        } else {
            accounts = accountList
        }
        do {
            return try await withThrowingTaskGroup(of: Balance.self) { group in
                
                var balance = Balance(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
                
                for account in accounts {
                    group.addTask {
                        var balance = Balance()
                        if(account.accountType == ConstantUtils.brokerAccountType) {
                            balance.currentValue = 0.0
                            balance.previousDayValue = 0.0
                            let brokerAccounts = await AccountInBrokerController().getAccountListInBroker(brokerID: account.id!)
                            for brokerAccount in brokerAccounts {
                                let brokerAccountBalance = await AccountInBrokerController().getCurrentBalanceOfAnAccountInBroker(accountBroker: brokerAccount)
                                balance.currentValue = balance.currentValue + brokerAccountBalance.currentValue
                                balance.previousDayValue = balance.previousDayValue + brokerAccountBalance.previousDayValue
                                balance.oneDayChange = balance.currentValue - balance.previousDayValue
                            }
                        } else {
                            if(account.currency != SettingsController().getDefaultCurrency().code) {
                                let financeDetailModel = await FinanceController().getCurrencyDetail(accountCurrency: account.currency)
                                balance.currentValue = financeDetailModel.regularMarketPrice ?? 0.0
                                balance.previousDayValue = financeDetailModel.chartPreviousClose ?? 0.0
                            }
                            let oneDayChange = await self.accountTransactionController.getAccountLastOneDayChange(accountID: account.id!)
                            balance.currentValue = balance.currentValue * oneDayChange.currentValue
                            balance.previousDayValue = balance.previousDayValue * oneDayChange.previousDayValue
                            balance.oneDayChange = oneDayChange.oneDayChange
                        }
                        return balance
                    }
                }
                
                for try await taskResult in group {
                    balance.currentValue += taskResult.currentValue
                    balance.previousDayValue += taskResult.previousDayValue
                    balance.oneDayChange += taskResult.oneDayChange
                }
                
                return balance
                
            }
        } catch {
            print(error)
        }
        return Balance(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
    }
    
    public func updateAccount(account: Account) async {
        do {
            let id = account.id!
            var updatedAccount = account
            updatedAccount.id = nil
            try getAccountCollection()
                .document(id)
                .setData(from: updatedAccount, merge: true)
            
            if(updatedAccount.deleted) {
                await updateWatchListIfAccountDeleted(accountID: account.id!)
            }
            
            await UserController().updateAccountUserData(updatedDate: account.lastUpdated)
            
            await ApplicationData.loadData()
        } catch {
            print(error)
        }
    }
    
    private func updateWatchListIfAccountDeleted(accountID: String) async {
        let watchList = await watchController.getAllWatchList()
        watchList.forEach { watch in
            if(watch.accountID.contains(accountID)) {
                watchController.deleteAccountFromWatchList(watchList: watch, accountID: accountID)
            }
        }
    }
    
    public func deleteAccount(accountID: String, isBrokerAccount: Bool) async {
        let watchList = await watchController.getAllWatchList()
        watchList.forEach { watch in
            if(watch.accountID.contains(accountID)) {
                watchController.deleteAccountFromWatchList(watchList: watch, accountID: accountID)
            }
        }
        if(isBrokerAccount) {
            let accountInBrokerList = await AccountInBrokerController().getAccountListInBroker(brokerID: accountID)
            for account in accountInBrokerList {
                CommonController.delete(collection: getAccountCollection().document(accountID).collection(ConstantUtils.accountBrokerCollectionName).document(account.id!).collection(ConstantUtils.accountTransactionCollectionName))
                do {
                    try await getAccountCollection().document(accountID).collection(ConstantUtils.accountBrokerCollectionName).document(account.id!).delete()
                } catch {
                    print(error)
                }
            }
        } else {
            CommonController.delete(collection: getAccountCollection().document(accountID).collection(ConstantUtils.accountTransactionCollectionName))
        }
        
        do {
            try await getAccountCollection().document(accountID).delete()
        } catch {
            print(error)
        }
        
        await ApplicationData.loadData()
    }
    
    public func deleteAccounts() async {
        let accountList = getAccountList()
        for account in accountList {
            await deleteAccount(accountID: account.id!, isBrokerAccount: account.accountType == ConstantUtils.brokerAccountType)
        }
    }
}
