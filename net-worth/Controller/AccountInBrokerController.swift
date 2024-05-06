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
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.ACCOUNT_BROKER.rawValue
    
    public func addAccountInBroker(accountInBroker: AccountInBroker) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(accountInBroker)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func getAccountListInBroker(brokerID: String) async -> [AccountInBroker] {
        print("Broker all by ID")
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: brokerID, forClass: [AccountInBroker].self)
        return response.sorted(by: {
            return $0.name < $1.name
        })
    }
    
    public func getAccountTransactionListInAccountInBrokerWithRange(brokerID: String, accountID: String, range: String) -> [AccountTransaction] {
        return [AccountTransaction]()
    }
    
    public func getAccountTransactionListInAccountInBrokerBelowRange(brokerID: String, accountID: String, range: String) -> [AccountTransaction] {
        return [AccountTransaction]()
    }
    
    public func deleteAccountInBroker(accountId: String) async {
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.DELETE.rawValue, pathParam: accountId, forClass: RestResponse.self)
    }
    
}
