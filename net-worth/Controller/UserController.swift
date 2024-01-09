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
    
    func addCurrentUser() {
        let currentUserDocument = getCurrentUserDocument()
        currentUserDocument.getDocument { [self] (document, error) in
            if let error = error {
                print("Error getting document: \(error)")
            } else if let document = document, document.exists {
                let data = document.data()
                print("Document data: \(data ?? [:])")
            } else {
                do {
                    try currentUserDocument.setData(from: User(id: getCurrentUserUID()))
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func isNewIncomeAvailable() async -> Bool {
        let user = await getCurrentUser()
        return ApplicationData.shared.data.incomeDataListUpdatedDate < user.incomeDataUpdatedDate
    }
    
    func isNewAccountAvailable() async -> Bool {
        let user = await getCurrentUser()
        return ApplicationData.shared.data.accountDataListUpdatedDate < user.accountDataUpdatedDate
    }
    
    func getCurrentUserUID() -> String {
        guard let userUID = Auth.auth().currentUser?.uid else { return "" }
        return userUID
    }
    
    func getCurrentUserDocument() -> DocumentReference {
        let db = Firestore.firestore()
        return db.collection(ConstantUtils.userCollectionName).document(getCurrentUserUID())
    }
    
    func getCurrentUser() async -> User {
        do {
            return try await UserController()
                .getCurrentUserDocument()
                .getDocument()
                .data(as: User.self)
        } catch {
            print(error)
        }
        return User(id: "")
    }
    
    func updateUser(user: User) {
        do {
            try getCurrentUserDocument()
                .setData(from: user, merge: true)
        } catch {
            print(error)
        }
    }
    
    func updateIncomeUserData(updatedDate: Date) async {
        var user = await getCurrentUser()
        user.incomeDataUpdatedDate = updatedDate
        
        updateUser(user: user)
    }
    
    func updateAccountUserData(updatedDate: Date) async {
        var user = await getCurrentUser()
        user.accountDataUpdatedDate = updatedDate
        
        updateUser(user: user)
    }
    
    func deleteUser() async {
        let db = Firestore.firestore()
        do {
            await AccountController().deleteAccounts()
            IncomeController().deleteIncomes()
            await WatchController().deleteWatchLists()
            IncomeTagController().deleteIncomeTags()
            IncomeTypeController().deleteIncomeTypes()
            try await db.collection(ConstantUtils.userCollectionName).document(getCurrentUserUID()).delete()
        } catch {
            print(error)
        }
    }
    
}
