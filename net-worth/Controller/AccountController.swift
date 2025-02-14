//
//  ItemViewController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import Foundation
import SwiftUI

class AccountController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.ACCOUNT.rawValue
    
    public func addAccount(newAccount: AccountRestModel) async {
//        let userId = ApplicationData.shared.userId
//        let requestData = Account(userId: userId, accountName: newAccount.accountName, accountType: newAccount.accountType, loanType: newAccount.loanType, currency: newAccount.currency, active: newAccount.active)
//        let encoder = JSONEncoder()
//        let data = try! encoder.encode(requestData)
//        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func updateAccount(account: AccountRestModel) async {
//        let userId = ApplicationData.shared.userId
//        let requestData = Account(id: account.id, userId: userId, accountName: account.accountName, accountType: account.accountType, loanType: account.loanType, currency: account.currency, active: account.active)
//        let encoder = JSONEncoder()
//        let data = try! encoder.encode(requestData)
//        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func deleteAccount(accountId: String) async {
//        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.DELETE.rawValue, pathParam: accountId, forClass: RestResponse.self)
    }
    
    public func getAccountList() async ->  [AccountRestModel] {
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: userId, forClass: [AccountRestModel].self)
        return response.sorted(by: {
            return $0.name < $1.name
        })
    }
    
    public func calculateTotalBalance(accountList: [AccountRestModel]) async -> Balance {
        var balance = Balance(currentValue: 0.0, previousDayValue: 0.0, oneDayChange: 0.0)
        accountList.forEach {
            balance.currentValue = balance.currentValue + $0.value.currentBalance
            balance.previousDayValue = balance.previousDayValue + $0.value.previousBalance
            balance.oneDayChange = balance.currentValue - balance.previousDayValue
        }
        return balance
    }
}
