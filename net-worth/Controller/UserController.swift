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
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.USER.rawValue
    
    func addCurrentUser() async {
        let userId = getCurrentUserUID()
        let requestData = UserRequest(userId: userId)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(requestData)
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: UserMainResponse.self)
        ApplicationData.shared.userId = response.result.data.id
    }
    
    func getCurrentUserUID() -> String {
        guard let userUID = Auth.auth().currentUser?.uid else { return "" }
        return userUID
    }
    
    func getCurrentUserDocument() -> DocumentReference {
        let db = Firestore.firestore()
        return db.collection(ConstantUtils.userCollectionName).document(getCurrentUserUID())
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
