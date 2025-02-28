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
    
    public func addIncomeTag(tag: TypeValueRestModel) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(tag)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func updateIncomeTag(tag: TypeValueRestModel) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(tag)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func getIncomeTagList() async -> [TypeValueRestModel] {
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: [userId], forClass: [TypeValueRestModel].self)
        return response.sorted(by: {
            return $0.name < $1.name
        })
    }
    
}
