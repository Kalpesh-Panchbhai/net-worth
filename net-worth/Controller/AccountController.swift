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
    
    var notificationController = NotificationController()
    var watchController = WatchController()
    var accountTransactionController = AccountTransactionController()
    
    public func addAccount(newAccount: Account) async -> String {
        do {
            let accountID = try getAccountCollection()
                .addDocument(from: newAccount).documentID
            
            await UserController().updateAccountUserData()
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
            let accountTransaction = AccountTransaction(timestamp: accountOpenedDate, balanceChange: newAccount.currentBalance, currentBalance: newAccount.currentBalance)
            await accountTransactionController.addTransaction(accountID: accountID, accountTransaction: accountTransaction)
            
            await UserController().updateAccountUserData()
            return accountID
        } catch {
            print(error)
        }
        return ""
    }
    
    public func getAccountCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
    }
    
    public func getAccount(id: String) -> Account {
        return ApplicationData.shared.accountList.keys.filter {
            $0.id!.elementsEqual(id)
        }.first!
    }
    
    public func getAccount(accountType: String) -> [Account]{
        return ApplicationData.shared.accountList.keys
            .filter {
                $0.accountType.elementsEqual(accountType)
            }
    }
    
    private func getAccountDataList() async -> [Account] {
        var accountList = [Account]()
        print("Updating Accounts")
        do {
            let backupAccountList = ApplicationData.shared.accountList
            accountList = try await getAccountCollection()
                .order(by: ConstantUtils.accountKeyAccountName)
                .getDocuments()
                .documents
                .map { doc in
                    return Account(doc: doc)
                }
            ApplicationData.shared.accountListUpdatedDate = await UserController().getCurrentUser().accountDataUpdatedDate
            // TODO: Update Account List
            var newAccountList = [Account: [AccountTransaction]]()
            
            for account in accountList {
                let isNewData = backupAccountList.filter {
                    $0.key.id!.elementsEqual(account.id!)
                }.first?.key.lastUpdated ?? account.lastUpdated.addingTimeInterval(-86400) < account.lastUpdated
                if(isNewData) {
                    let accountTransactionList = await accountTransactionController.getAccountTransactionDataList(accountID: account.id!)
                    newAccountList.updateValue(accountTransactionList, forKey: account)
                } else {
                    let accountTransactionList = backupAccountList.filter {
                        $0.key.id!.elementsEqual(account.id!)
                    }.first?.value ?? [AccountTransaction]()
                    newAccountList.updateValue(accountTransactionList, forKey: account)
                }
            }
            
            ApplicationData.shared.accountList = newAccountList
        } catch {
            print(error)
        }
        print("Accounts Updated")
        return accountList
    }
    
    public func getAccountList() async -> [Account] {
        var accountList = [Account]()
        if(await UserController().isNewAccountAvailable()) {
            print("New Accounts")
            accountList = await getAccountDataList()
        } else {
            print("Old Accounts")
            accountList = Array(ApplicationData.shared.accountList.keys)
        }
        return accountList.sorted(by: {
            $0.accountName < $1.accountName
        })
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
                        let accountTransaction = await self.accountTransactionController.getLastTwoAccountTransactionList(accountID: account.id!)
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
    
    public func updateAccount(account: Account) async {
        do {
            try getAccountCollection()
                .document(account.id!)
                .setData(from: account, merge: true)
            
            await UserController().updateAccountUserData()
        } catch {
            print(error)
        }
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
        
        await UserController().updateAccountUserData()
    }
    
    public func deleteAccounts() async {
        let accountList = await getAccountList()
        for account in accountList {
            await deleteAccount(account: account)
        }
    }
}
