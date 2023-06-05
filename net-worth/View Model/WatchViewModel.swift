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
        DispatchQueue.main.async {
            self.watchList = list
            self.watchListLoad = true
        }
    }
    
    func getAllWatchListWithAccountDetails() async {
        let watchList = await watchController.getAllWatchList()
        var watchListWithAccount2 = [Watch: [Account]]()
        for list in watchList {
            var accountList = [Account]()
            for i in 0..<list.accountID.count {
                let account = await accountController.getAccount(id: list.accountID[i])
                accountList.append(account)
            }
            watchListWithAccount2.updateValue(accountList, forKey: list)
        }
        let watchListWithAccount1 = watchListWithAccount2
        DispatchQueue.main.async {
            self.watchListWithAccount = watchListWithAccount1
        }
    }
    
    func getWatchList(id: String) async {
        let item = await watchController.getWatchList(id: id)
        DispatchQueue.main.async {
            self.watch = item
        }
    }
    
    func getWatchListByAccount(accountID: String) async {
        let list = await watchController.getWatchListByAccount(accountID: accountID)
        DispatchQueue.main.async {
            self.watchListForAccount = list
        }
    }
}
