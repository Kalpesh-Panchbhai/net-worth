//
//  AccountTransactionController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/06/23.
//

import Foundation

class AccountTransactionController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.ACCOUNT_TRANSACTION.rawValue
    
    public func addAccountTransaction(accountTransaction: AccountTransactionRestModel) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(accountTransaction)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func deleteAccountTransaction(id: Int) async {
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.DELETE.rawValue, pathParam: [id], forClass: RestResponse.self)
    }
    
    public func getAccountTransactionList(accountID: Int, type: String) async ->  [AccountTransactionRestModel] {
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: [accountID, type], forClass: [AccountTransactionRestModel].self)
        return response.sorted(by: {
            return $0.transactionDate > $1.transactionDate
        })
    }
}
