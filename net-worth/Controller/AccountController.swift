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
    
    public func addAccount(newAccount: Account) async {
        let userId = ApplicationData.shared.userId
        let requestData = Account(userId: userId, accountName: newAccount.accountName, accountType: newAccount.accountType, loanType: newAccount.loanType, currency: newAccount.currency, active: newAccount.active)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(requestData)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func updateAccount(account: Account) async {
        let userId = ApplicationData.shared.userId
        let requestData = Account(id: account.id, userId: userId, accountName: account.accountName, accountType: account.accountType, loanType: account.loanType, currency: account.currency, active: account.active)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(requestData)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func deleteAccount(accountId: String) async {
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.DELETE.rawValue, pathParam: accountId, forClass: RestResponse.self)
    }
    
    public func getAccount(id: String) async -> Account {
        let accountList = await getAccountList()
        let account = accountList.first(where: {
            return $0.id.elementsEqual(id)
        })
        
        return account ?? Account()
    }
    
    public func getAccountList() async ->  [Account] {
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: userId, forClass: [Account].self)
        return response.sorted(by: {
            return $0.accountName < $1.accountName
        })
    }
    
    public func calculateTotalBalance(accountList: [Account]) async -> Balance {
        return Balance(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
    }
}
