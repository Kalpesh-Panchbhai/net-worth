//
//  AccountViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation
import FirebaseFirestore

class AccountViewModel: ObservableObject {
    
    @Published var accountList = [Account]()
    
    @Published var accountTransactionList = [AccountTransaction]()
    
    func addAccount(account: Account) -> String {
        do {
            let accountID = try UserController()
                .getCurrentUserDocument()
                .collection(ConstantUtils.accountCollectionName)
                .addDocument(from: account).documentID
            return accountID
        } catch {
            print(error)
        }
        return ""
    }
    
    func updateAccount(id: String, account: Account) {
        do {
            try UserController()
                .getCurrentUserDocument()
                .collection(ConstantUtils.accountCollectionName)
                .document(id)
                .setData(from: account, merge: true)
        } catch {
            print(error)
        }
    }
    
    func addTransaction(accountID: String, accountTransaction: AccountTransaction) {
        do {
            let documentID = try UserController()
                .getCurrentUserDocument()
                .collection(ConstantUtils.accountCollectionName)
                .document(accountID)
                .collection(ConstantUtils.accountTransactionCollectionName)
                .addDocument(from: accountTransaction).documentID
            
            print("New Account transaction added : " + documentID)
        } catch {
            print(error)
        }
    }
    
    func getAccountList() {
        UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
            .getDocuments { snapshot, error in
                if error == nil {
                    if let snapshot = snapshot {
                        self.accountList = snapshot.documents.map { doc in
                            return Account(doc: doc)
                        }
                    }
                } else {
                    
                }
            }
    }
    
    func getAccountTransactionList(id: String) {
        UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
            .document(id)
            .collection(ConstantUtils.accountTransactionCollectionName)
            .order(by: ConstantUtils.accountTransactionKeytimestamp, descending: true)
            .getDocuments { snapshot, error in
                if error == nil {
                    if let snapshot = snapshot {
                        self.accountTransactionList = snapshot.documents.map { doc in
                            return AccountTransaction(id: doc.documentID,
                                                timestamp: (doc[ConstantUtils.accountTransactionKeytimestamp] as? Timestamp)?.dateValue() ?? Date(),
                                                balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0)
                        }
                    }
                } else {
                    
                }
                
            }
    }
}
