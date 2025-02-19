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
    
    @Published var watchList = [WatchRestModel]()
    @Published var watchListLoad = false
    @Published var watch = WatchRestModel()
    
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
        var allList = [WatchRestModel]()
        allList.append(allWatch)
        allList.append(contentsOf: otherThanAllWatch)
        let returnAllList = allList
        DispatchQueue.main.async {
            self.watchList = returnAllList
            self.watchListLoad = true
        }
    }
}
