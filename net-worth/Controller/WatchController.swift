//
//  WatchController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import Foundation

class WatchController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.WATCH.rawValue
    
    public func addWatchList(watch: WatchRestModel) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(watch)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func getAllWatchList() async -> [WatchRestModel] {
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: [userId], forClass: [WatchRestModel].self)
        return response
    }
    
    public func updateWatchList(watch: WatchRestModel) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(watch)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func deleteWatchList(watch: WatchRestModel) async {
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.DELETE.rawValue, pathParam: [watch.id], forClass: RestResponse.self)
    }
}
