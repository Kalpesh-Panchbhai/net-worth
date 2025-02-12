//
//  WatchViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import Foundation

class WatchViewModel: ObservableObject {
    
    var watchController = WatchController()
    var accountController = AccountController()
    
    @Published var watchList = [Watch]()
    @Published var watchListLoad = false
    @Published var watchListForAccount = [Watch]()
    @Published var watchListWithAccount = [Watch: [Account]]()
    @Published var watch = Watch()
    
    func getAllWatchList() async {
        let list = await watchController.getAllWatchList()
        let allWatch = list.first(where: {
            return $0.name.elementsEqual("All")
        })!
        var otherThanAllWatch = list.filter {
            return !$0.name.elementsEqual("All")
        }
        otherThanAllWatch.sort(by: {
            return $0.name < $1.name
        })
        var allList = [Watch]()
        allList.append(allWatch)
        allList.append(contentsOf: otherThanAllWatch)
        let returnAllList = allList
        DispatchQueue.main.async {
            self.watchList = returnAllList
            self.watchListLoad = true
        }
    }
    
    func getWatchListByAccount(accountID: Int) async {
//        let list = watchList.filter {
//            return $0.accountList.contains(accountID)
//        }
//        DispatchQueue.main.async {
//            self.watchListForAccount = list
//        }
    }
}
