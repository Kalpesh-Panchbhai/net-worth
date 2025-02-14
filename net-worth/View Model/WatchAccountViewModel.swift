//
//  WatchViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import Foundation

class WatchAccountViewModel: ObservableObject {
    
    var watchAccountController = WatchAccountController()
    
    @Published var allAccountsByWatchID = [WatchAccountRestModel]()
    
    func getAllAccountsByWatchID(watchID: Int) async {
        let allAccountsByWatchID = await watchAccountController.getAllAccountsByWatchID(watchID: watchID)
        DispatchQueue.main.async {
            self.allAccountsByWatchID = allAccountsByWatchID
        }
    }
}
