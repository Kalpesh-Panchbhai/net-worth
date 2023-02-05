//
//  AccountViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation

class AccountViewModel: ObservableObject {
    
    @Published var accountList = [Accountss]()
    
    func addAccount(account: Accountss) -> String {
        do {
            var accountID = try UserController()
                .getCurrentUserDocument()
                .collection(ConstantUtils.accountCollectionName)
                .addDocument(from: account).documentID
            return accountID
        } catch {
            print(error)
        }
        return ""
    }
    
    func addTransaction(accountID: String, accountTransaction: AccountTrans) {
        do {
            try UserController()
                .getCurrentUserDocument()
                .collection(ConstantUtils.accountCollectionName)
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .addDocument(from: accountTransaction)
        } catch {
            print(error)
        }
    }
}
