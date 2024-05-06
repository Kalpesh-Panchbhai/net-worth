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
    
    public func addTransaction(accountTransaction: AccountTransaction) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(accountTransaction)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func getTransactionList(accountId: String) async -> [AccountTransaction] {
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: accountId, forClass: [AccountTransaction].self)
        return response.sorted(by: {
            return $0.timestamp > $1.timestamp
        })
    }
}
