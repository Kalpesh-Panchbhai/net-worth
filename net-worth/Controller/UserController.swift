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
        do {
            try getCurrentUserDocument().setData(from: User(id: getCurrentUserUID()))
        } catch {
            print(error)
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
    
    func updateIncomeUserData() async {
        var user = await getCurrentUser()
        user.incomeDataUpdatedDate = Date.now
        
        updateUser(user: user)
    }
    
    func updateAccountUserData() async {
        var user = await getCurrentUser()
        user.accountDataUpdatedDate = Date.now
        
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
