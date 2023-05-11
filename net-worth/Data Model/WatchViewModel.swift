//
//  WatchViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import Foundation

class WatchViewModel: ObservableObject {
    
    @Published var watchList = [Watch]()
    @Published var watchListLoad = false
    @Published var watchListForAccount = [Watch]()
    @Published var watch = Watch()
    
    private var watchController = WatchController()
    
    func getAllWatchList() async {
        do {
            let list = try await watchController.getAllWatchList()
            DispatchQueue.main.async {
                self.watchList = list
                self.watchListLoad = true
            }
        } catch {
            print(error)
        }
    }
    
    func getWatchList(id: String) async {
        do {
            let item = try await watchController.getWatchList(id: id)
            DispatchQueue.main.async {
                self.watch = item
            }
        } catch {
            print(error)
        }
    }
    
    func getWatchListByAccount(accountID: String) async {
        do {
            let list = try await watchController.getWatchListByAccount(accountID: accountID)
            DispatchQueue.main.async {
                self.watchListForAccount = list
            }
        } catch {
            print(error)
        }
    }
}
