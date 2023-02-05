//
//  AccountViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation
import FirebaseFirestore

class AccountViewModel: ObservableObject {
    
    @Published var accountList = [Accountss]()
    
    @Published var accountTransactionList = [AccountTrans]()
    
    func addAccount(account: Accountss) -> String {
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
    
    func updateAccount(id: String, account: Accountss) {
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
    
    func getAccountList() {
        UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.accountCollectionName)
            .getDocuments { snapshot, error in
                if error == nil {
                    if let snapshot = snapshot {
                        self.accountList = snapshot.documents.map { doc in
                            return Accountss(doc: doc)
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
                            return AccountTrans(id: doc.documentID,
                                                timestamp: (doc[ConstantUtils.accountTransactionKeytimestamp] as? Timestamp)?.dateValue() ?? Date(),
                                                balanceChange: doc[ConstantUtils.accountTransactionKeyBalanceChange] as? Double ?? 0.0)
                        }
                    }
                } else {
                    
                }
                
            }
    }
}