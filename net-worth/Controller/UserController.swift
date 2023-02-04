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
        let db = Firestore.firestore()
        do {
            try getCurrentUserDocument().setData(from: User(id: getCurrentUserUID()))
        } catch {
            print(error)
        }
    }
    
    func getCurrentUserDocument() -> DocumentReference {
        let db = Firestore.firestore()
        return db.collection("users").document(getCurrentUserUID())
    }
}
