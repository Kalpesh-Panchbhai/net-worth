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
    
    func getCurrentUser() async throws -> User {
        return try await UserController()
            .getCurrentUserDocument()
            .getDocument()
            .data(as: User.self)
    }
    
    func updateUser(user: User) {
        do {
            try getCurrentUserDocument()
                .setData(from: user, merge: true)
        } catch {
            print(error)
        }
    }
    
    func updateIncomeUserData() async {
        do {
            var user = try await getCurrentUser()
            user.incomeDataUpdatedDate = Date.now
            
            updateUser(user: user)
        } catch {
            print(error)
        }
    }
    
    func isNewIncomeAvailable() async -> Bool {
        do {
            let user = try await getCurrentUser()
            return ApplicationData.shared.incomeListUpdatedDate < user.incomeDataUpdatedDate
        } catch {
            print(error)
        }
        
        return true
    }
    
    func deleteUser() async {
        let db = Firestore.firestore()
        do {
            try await AccountController().deleteAccounts()
            IncomeController().deleteIncomes()
            try await WatchController().deleteWatchLists()
            IncomeController().deleteIncomeTags()
            IncomeController().deleteIncomeTypes()
            try await db.collection(ConstantUtils.userCollectionName).document(getCurrentUserUID()).delete()
        } catch {
            print(error)
        }
    }
    
}
