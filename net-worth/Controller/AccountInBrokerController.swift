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
        return accountTransactionList
    }
    
    public func addAccountInBroker(brokerID: String, accountInBroker: AccountInBroker) async {

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
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: userId, forClass: [Account].self)
        return response.sorted(by: {
            return $0.accountName < $1.accountName
        })
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
        return [AccountTransaction]()
    }
    
    public func getAccountTransactionListInAccountInBrokerBelowRange(brokerID: String, accountID: String, range: String) -> [AccountTransaction] {
        return [AccountTransaction]()
    }
    
    public func getCurrentBalanceOfAnAccountInBroker(accountBroker: AccountInBroker) async -> Balance {
        let chartData = ApplicationData.shared.chartDataList.first(where: {
            return $0.key.elementsEqual(accountBroker.id ?? "")
        })?.value ?? [ChartData]()
        var currentBalance = Balance(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
        if(chartData.count > 0) {
            currentBalance.currentValue = chartData.last!.value
            if(chartData.count > 1) {
                currentBalance.previousDayValue = chartData[chartData.count - 2].value
            }
            currentBalance.oneDayChange = currentBalance.currentValue - currentBalance.previousDayValue
        }
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
        
    }
    
    public func deleteTransactionInAccountInBroker(brokerID: String, accountID: String) async {
        
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
