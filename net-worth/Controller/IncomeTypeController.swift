//
//  IncomeTypeController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/06/23.
//
import Foundation

class IncomeTypeController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.INCOME_TYPE.rawValue
    
    public func addIncomeType(type: TypeValueRestModel) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(type)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func updateIncomeType(type: TypeValueRestModel) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(type)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func getIncomeTypeList() async -> [TypeValueRestModel] {
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: userId, forClass: [TypeValueRestModel].self)
        return response.sorted(by: {
            return $0.name < $1.name
        })
    }
}
