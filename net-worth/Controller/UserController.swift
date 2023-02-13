//
//  UtilController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/02/23.
//

import Foundation
import Firebase
import FirebaseFirestore

class UserController {
    
    func getCurrentUserUID() -> String {
        guard let userUID = Auth.auth().currentUser?.uid else { return "" }
        return userUID
    }
    
    func addCurrentUser() {
        do {
            try getCurrentUserDocument().setData(from: User(id: getCurrentUserUID()))
        } catch {
            print(error)
        }
    }
    
    func getCurrentUserDocument() -> DocumentReference {
        let db = Firestore.firestore()
        return db.collection(ConstantUtils.userCollectionName).document(getCurrentUserUID())
    }
    
    func deleteUser() async {
        let db = Firestore.firestore()
        do {
            try await AccountController().deleteAccounts()
            IncomeController().deleteIncomes()
            try await db.collection(ConstantUtils.userCollectionName).document(getCurrentUserUID()).delete()
        } catch {
            print(error)
        }
    }
    
}
