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
        return db.collection(ConstantUtils().usersCollectionName).document(getCurrentUserUID())
    }
    
    func deleteUser() {
        let db = Firestore.firestore()
        delete(collection: db.collection(ConstantUtils().usersCollectionName).document(getCurrentUserUID()).collection(ConstantUtils().incomeCollectionName))
        db.collection(ConstantUtils().usersCollectionName).document(getCurrentUserUID()).delete()
    }
    
    func delete(collection: CollectionReference, batchSize: Int = 100) {
        collection.limit(to: batchSize).getDocuments { (docset, error) in
          let docset = docset

          let batch = collection.firestore.batch()
          docset?.documents.forEach { batch.deleteDocument($0.reference) }

          batch.commit {_ in
            self.delete(collection: collection, batchSize: batchSize)
          }
        }
      }
}
