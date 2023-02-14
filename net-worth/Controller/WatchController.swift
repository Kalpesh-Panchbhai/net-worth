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
    
    public func getAllWatchList() async throws -> [Watch] {
        var watchList = [Watch]()
        watchList = try await getWatchCollection()
            .order(by: ConstantUtils.watchKeyWatchName)
            .getDocuments()
            .documents
            .map { doc in
                return Watch(doc: doc)
            }
        return watchList
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
    
    public func updateWatchList(watchList: Watch) {
        do {
            try getWatchCollection()
                .document(watchList.id!)
                .setData(from: watchList, merge: true)
        } catch {
            print(error)
        }
    }
    
    public func deleteWatchLists() async throws {
        let watchList = try await getAllWatchList()
        for watch in watchList {
            deleteWatchList(watchList: watch)
        }
    }
    
    public func deleteWatchList(watchList: Watch) {
        getWatchCollection().document(watchList.id!).delete()
    }
}
