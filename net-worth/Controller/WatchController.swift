//
//  WatchController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import Foundation
import FirebaseFirestore

class WatchController {
    
    private func getWatchCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.watchCollectionName)
    }
    
    public func addWatchList(watchList: Watch) {
        do {
            let documentID = try getWatchCollection()
                .addDocument(from: watchList).documentID
            print("New Watch List created : " + documentID)
        } catch {
            print(error)
        }
    }
    
    public func addDefaultWatchList() async {
        let count = await getAllWatchList().count
        if(count == 0) {
            var watchList = Watch()
            watchList.accountName = "All"
            addWatchList(watchList: watchList)
        }
    }
    
    public func addAccountToWatchList(watch: Watch) {
        do {
            try getWatchCollection()
                .document(watch.id!)
                .setData(from: watch, merge: true)
        } catch {
            print(error)
        }
    }
    
    public func getAllWatchList() async -> [Watch] {
        var watchList = [Watch]()
        do {
            watchList = try await getWatchCollection()
                .order(by: ConstantUtils.watchKeyWatchName)
                .getDocuments()
                .documents
                .map { doc in
                    return Watch(doc: doc)
                }.sorted(by: { item1, item2 in
                    item1.accountName < item2.accountName
                })
        } catch {
            print(error)
        }
        var returnWatchList = watchList.filter { item in
            !item.accountName.elementsEqual("All")
        }
        returnWatchList.insert(contentsOf: watchList.filter { item in
            item.accountName.elementsEqual("All")
        }, at: 0)
        return returnWatchList
    }
    
    public func getDefaultWatchList() async -> Watch {
        var watch = Watch()
        do {
            watch = try await getWatchCollection()
                .whereField(ConstantUtils.watchKeyWatchName, isEqualTo: "All")
                .getDocuments()
                .documents
                .map { doc in
                    return Watch(doc: doc)
                }.first!
        } catch {
            print(error)
        }
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
    
    public func getWatchListByAccount(accountID: String) async -> [Watch] {
        var watch = [Watch]()
        do {
            watch = try await getWatchCollection()
                .getDocuments()
                .documents
                .map { doc in
                    return Watch(doc: doc)
                }
            watch = watch.filter { item in
                item.accountID.contains(accountID)
            }.sorted(by: { item1, item2 in
                item1.accountName < item2.accountName
            })
        } catch {
            print(error)
        }
        var returnWatchList = watch.filter { item in
            !item.accountName.elementsEqual("All")
        }
        returnWatchList.insert(contentsOf: watch.filter { item in
            item.accountName.elementsEqual("All")
        }, at: 0)
        return returnWatchList
    }
    
    public func updateWatchList(watchList: Watch) {
        do {
            try getWatchCollection()
                .document(watchList.id!)
                .setData(from: watchList, merge: true)
        } catch {
            print(error)
        }
    }
    
    public func deleteWatchLists() async {
        let watchList = await getAllWatchList()
        for watch in watchList {
            deleteWatchList(watchList: watch)
        }
    }
    
    public func deleteWatchList(watchList: Watch) {
        getWatchCollection().document(watchList.id!).delete()
    }
    
    public func deleteAccountFromWatchList(watchList: Watch, accountID: String) {
        var watchList = watchList
        watchList.accountID = watchList.accountID.filter { id in
            id != accountID
        }
        updateWatchList(watchList: watchList)
    }
}
