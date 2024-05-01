//
//  IncomeTagController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/06/23.
//

import FirebaseFirestore

class IncomeTagController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.INCOME_TAG.rawValue
    
    public func addIncomeTag(tag: IncomeTag) async {
        let userId = ApplicationData.shared.userId
        let requestData = TypeValueRequest(name: tag.name, user: userId, isDefault: tag.isdefault)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(requestData)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: TypeValueMainResponse.self)
    }
    
    public func updateIncomeTag(tag: IncomeTag) async {
        let userId = ApplicationData.shared.userId
        let requestData = TypeValueRequest(name: tag.name, user: userId, isDefault: tag.isdefault)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(requestData)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, pathParam: tag.id, forClass: TypeValueMainResponse.self)
    }
    
    public func getIncomeTagList() async -> [IncomeTag] {
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: userId, forClass: TypeValueMainResponse.self)
        return response.result.data.map {
            return IncomeTag(id: $0.id, name: $0.name, isdefault: $0.isDefault)
        }.sorted(by: {
            return $0.name < $1.name
        })
    }
    
    public func deleteIncomeTags() {
        CommonController.delete(collection: UserController().getCurrentUserDocument().collection(ConstantUtils.incomeTagCollectionName))
    }
    
}
