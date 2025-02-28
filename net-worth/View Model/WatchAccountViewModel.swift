//
//  WatchViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import Foundation

class WatchAccountViewModel: ObservableObject, @unchecked Sendable {
    
    var watchAccountController = WatchAccountController()
    
    @Published var allAccountsByWatchID = [WatchAccountRestModel]()
    @Published var allWatchListByAccountID = [WatchAccountRestModel]()
    
    func getAllAccountsByWatchID(watchID: Int) async {
        let allAccountsByWatchID = await watchAccountController.getAllAccountsByWatchID(watchID: watchID)
        DispatchQueue.main.async {
            self.allAccountsByWatchID = allAccountsByWatchID
        }
    }
    
    func getAllWatchListByAccountID(accountID: Int) async {
        let allWatchListByAccountID = await watchAccountController.getAllWatchListByAccountID(accountID: accountID)
        DispatchQueue.main.async {
            self.allWatchListByAccountID = allWatchListByAccountID
        }
    }
}
