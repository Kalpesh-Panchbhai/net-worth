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
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.ACCOUNT.rawValue
    
    public func getAccountCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
    }
    
    public func addAccount(newAccount: Account) async -> String {
        let userId = ApplicationData.shared.userId
        let requestData = AccountRestModel(accountType: newAccount.accountType, loanType: newAccount.loanType, accountName: newAccount.accountName, currentBalance: newAccount.currentBalance, paymentReminder: newAccount.paymentReminder, paymentDate: newAccount.paymentDate, currency: newAccount.currency, active: newAccount.active, userId: userId, accountOpenedDate: "")
        let encoder = JSONEncoder()
        let data = try! encoder.encode(requestData)
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: AccountRestModel.self)
        return response.id
    }
    
    public func addAccount(newAccount: Account, accountOpenedDate: Date) async -> String {
        let userId = ApplicationData.shared.userId
        let requestData = AccountRestModel(accountType: newAccount.accountType, loanType: newAccount.loanType, accountName: newAccount.accountName, currentBalance: newAccount.currentBalance, paymentReminder: newAccount.paymentReminder, paymentDate: newAccount.paymentDate, currency: newAccount.currency, active: newAccount.active, userId: userId, accountOpenedDate: accountOpenedDate.convertToGlideDateTimeFormat())
        let encoder = JSONEncoder()
        let data = try! encoder.encode(requestData)
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: AccountRestModel.self)
        return response.id
    }
    
    public func updateAccount(account: Account) async {
        let userId = ApplicationData.shared.userId
        let requestData = AccountRestModel(id: account.id!, accountType: account.accountType, loanType: account.loanType, accountName: account.accountName, currentBalance: account.currentBalance, paymentReminder: account.paymentReminder, paymentDate: account.paymentDate, currency: account.currency, active: account.active, userId: userId, accountOpenedDate: "")
        let encoder = JSONEncoder()
        let data = try! encoder.encode(requestData)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, forClass: AccountRestModel.self)
    }
    
    public func deleteAccount(accountId: String) async {
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.DELETE.rawValue, pathParam: accountId, forClass: [AccountRestModel].self)
    }
    
    public func getAccount(id: String) async -> Account {
        let accountList = await getAccountList()
        let account = accountList.first(where: {
            return $0.id!.elementsEqual(id)
        })
        
        return account ?? Account()
    }
    
    public func getAccountList() async ->  [Account] {
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: userId, forClass: [AccountRestModel].self)
        return response.map {
            return Account(id: $0.id,
                           accountType: $0.accountType,
                           loanType: $0.loanType,
                           accountName: $0.accountName,
                           currentBalance: $0.currentBalance,
                           paymentReminder: $0.paymentReminder,
                           paymentDate: $0.paymentDate,
                           currency: $0.currency,
                           active: $0.active)
        }.sorted(by: {
            return $0.accountName < $1.accountName
        })
    }
    
    public func getAccountList(accountType: String) async -> [Account] {
        let accountList = await getAccountList()
        return accountList.filter {
            return $0.accountType.elementsEqual(accountType)
        }
    }
    
    public func calculateTotalBalance(accountList: [Account]) async -> Balance {
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
                        if(account.accountType == ConstantUtils.brokerAccountType) {
                            balance.currentValue = 0.0
                            balance.previousDayValue = 0.0
                            let brokerAccounts = AccountInBrokerController().getAccountListInBroker(brokerID: account.id!)
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
}
