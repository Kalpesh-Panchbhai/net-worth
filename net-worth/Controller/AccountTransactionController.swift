//
//  AccountTransactionController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/06/23.
//

import Foundation
import FirebaseFirestore

class AccountTransactionController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.ACCOUNT_TRANSACTION.rawValue
    
    public func getTransactionList(accountId: String) async -> [AccountTransaction] {
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: accountId, forClass: [AccountTransactionRestModel].self)
        return response.map {
            return AccountTransaction(id: $0.id,
                                      timestamp: $0.timestamp.convertFromGlideDateTimeFormat(),
                                      currentBalance: $0.currentBalance,
                                      paid: $0.paid)
        }.sorted(by: {
            return $0.timestamp > $1.timestamp
        })
    }
    
    public func addTransaction(accountID: String, accountTransaction: AccountTransaction) async {
        do {
            let documentID = try AccountController().getAccountCollection()
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .addDocument(from: accountTransaction).documentID
            
            print("New Account transaction added : " + documentID)
            
        } catch {
            print(error)
        }
    }
    
    public func addTransaction(accountID: String, account: Account, timestamp: Date, operation: String) async {
        let currentDateTime = Date.now
    }
    
    public func addLoanAccountEMITransaction(account: Account, emiDate: Int, accountOpenedDate: Date, monthlyEmiAmount: Double) async {
    }
    
    public func updateAccountTransaction(accountID: String, accountTransaction: AccountTransaction) async {
        do {
            let accountTransactionID = accountTransaction.id!
            var updatedAccountTransaction = accountTransaction
            updatedAccountTransaction.id = nil
            try AccountController().getAccountCollection()
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .document(accountTransactionID)
                .setData(from: updatedAccountTransaction, merge: true)
        } catch {
            print(error)
        }
    }
    
}
