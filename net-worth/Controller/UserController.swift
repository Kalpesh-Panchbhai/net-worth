//
//  UtilController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/02/23.
//

import Foundation
import Firebase

class UserController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.USER.rawValue
    
    func addCurrentUser() async {
        let userId = getCurrentUserUID()
        let requestData = UserRestModel(userId: userId)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(requestData)
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
//        ApplicationData.shared.userId = response.id
    }
    
    func getCurrentUserUID() -> String {
        guard let userUID = Auth.auth().currentUser?.uid else { return "" }
        return userUID
    }
    
    func deleteUser() async {
        let userId = ApplicationData.shared.userId
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.DELETE.rawValue, pathParam: userId, forClass: RestResponse.self)
    }
    
}
