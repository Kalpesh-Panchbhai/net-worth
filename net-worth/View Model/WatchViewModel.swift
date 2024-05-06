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
    
    func getWatchListByAccount(accountID: String) async {
        let list = watchList.filter {
            return $0.accountList.contains(accountID)
        }
        DispatchQueue.main.async {
            self.watchListForAccount = list
        }
    }
}
