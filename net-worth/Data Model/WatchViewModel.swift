//
//  WatchViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import Foundation

class WatchViewModel: ObservableObject {
    
    @Published var watchList = [Watch]()
    
    private var watchController = WatchController()
    
    func getAllWatchList() async {
        do {
            let list = try await watchController.getAllWatchList()
            DispatchQueue.main.async {
                self.watchList = list
            }
        } catch {
            print(error)
        }
    }
}
