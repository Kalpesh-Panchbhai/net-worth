//
//  IncomeTypeController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/06/23.
//

import FirebaseFirestore

class IncomeTypeController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.INCOME_TYPE.rawValue
    
    public func addIncomeType(type: IncomeType) async {
        let userId = ApplicationData.shared.userId
        let requestData = TypeValueRestModel(name: type.name, userId: userId, isDefault: type.isdefault)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(requestData)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: TypeValueRestModel.self)
    }
    
    public func updateIncomeType(type: IncomeType) async {
        let userId = ApplicationData.shared.userId
        let requestData = TypeValueRestModel(name: type.name, userId: userId, isDefault: type.isdefault)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(requestData)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, pathParam: type.id, forClass: TypeValueRestModel.self)
    }
    
    public func getIncomeTypeList() async -> [IncomeType] {
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: userId, forClass: [TypeValueRestModel].self)
        return response.map {
            return IncomeType(id: $0.id, name: $0.name, isdefault: $0.isDefault)
        }.sorted(by: {
            return $0.name < $1.name
        })
    }
    
    public func deleteIncomeTypes() {
        CommonController.delete(collection: UserController().getCurrentUserDocument().collection(ConstantUtils.incomeTypeCollectionName))
    }
    
}
