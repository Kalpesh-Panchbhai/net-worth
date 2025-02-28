//
//  WatchController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import Foundation

class WatchAccountController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.WATCH_ACCOUNT.rawValue
    
    public func addWatchAccount(watch: WatchAccountRestModel) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(watch)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func deleteWatchAccount(id: Int) async {
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.DELETE.rawValue, pathParam: [id], forClass: RestResponse.self)
    }
    
    public func getAllAccountsByWatchID(watchID: Int) async -> [WatchAccountRestModel] {
        return await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: [watchID, "watch"], forClass: [WatchAccountRestModel].self)
    }
    
    public func getAllWatchListByAccountID(accountID: Int) async -> [WatchAccountRestModel] {
        return await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: [accountID, "account"], forClass: [WatchAccountRestModel].self)
    }
}
