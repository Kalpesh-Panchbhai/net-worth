//
//  WatchController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import Foundation
import FirebaseFirestore

class WatchController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.WATCH.rawValue
    
    private func getWatchCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.watchCollectionName)
    }
    
    public func addWatchList(watch: Watch) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(watch)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func addDefaultWatchList() async {
        let count = await getAllWatchList().count
        if(count == 0) {
            var watchList = Watch()
            watchList.name = "All"
            watchList.userId = ApplicationData.shared.userId
            await addWatchList(watch: watchList)
        }
    }
    
    public func getAllWatchList() async -> [Watch] {
        print("Watch All")
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: userId, forClass: [Watch].self)
        return response
    }
    
    public func getDefaultWatchList() async -> Watch {
        var watch = Watch()
        return watch
    }
    
    public func getWatchList(id: String) async -> Watch {
        var watch = Watch()
        do {
            watch = try await getWatchCollection()
                .document(id)
                .getDocument()
                .data(as: Watch.self)
        } catch {
            print(error)
        }
        return watch
    }
    
    public func updateWatchList(watch: Watch) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(watch)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func deleteWatchLists() async {
        let watchList = await getAllWatchList()
        for watch in watchList {
            await deleteWatchList(watch: watch)
        }
    }
    
    public func deleteWatchList(watch: Watch) async {
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.DELETE.rawValue, pathParam: watch.id, forClass: RestResponse.self)
    }
    
    public func deleteAccountFromWatchList(watchList: Watch, accountID: String) {
        var watchList = watchList
        watchList.accountList = watchList.accountList.filter { id in
            id != accountID
        }
//        updateWatchList(watchList: watchList)
    }
    
    public func addAccountToWatch(watch: Watch, accountId: String) async {
        await updateWatchList(watch: watch)
    }
}
