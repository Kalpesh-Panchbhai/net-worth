//
//  IncomeTagController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/06/23.
//

import Foundation

class IncomeTagController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.INCOME_TAG.rawValue
    
    public func addIncomeTag(tag: IncomeTag) async {
        let userId = ApplicationData.shared.userId
        let requestData = TypeValueRestModel(userId: userId, name: tag.name, isDefault: tag.isdefault)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(requestData)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func updateIncomeTag(tag: IncomeTag) async {
        let userId = ApplicationData.shared.userId
        let requestData = TypeValueRestModel(id: tag.id, userId: userId, name: tag.name, isDefault: tag.isdefault)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(requestData)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func getIncomeTagList() async -> [IncomeTag] {
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: userId, forClass: [TypeValueRestModel].self)
        return response.map {
            return IncomeTag(id: $0.id, name: $0.name, isdefault: $0.isDefault)
        }.sorted(by: {
            return $0.name < $1.name
        })
    }
    
}
