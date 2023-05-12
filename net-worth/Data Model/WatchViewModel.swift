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
    @Published var watchListWithAccount = [Watch: [Account]]()
    @Published var watch = Watch()
    
    private var watchController = WatchController()
    private var accountController = AccountController()
    
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
    
    func getAllWatchListWithAccountDetails() async {
        do {
            let watchList = try await watchController.getAllWatchList()
            var watchListWithAccount2 = [Watch: [Account]]()
            for list in watchList {
                do {
                    var accountList = [Account]()
                    for i in 0..<list.accountID.count {
                        let account = try await accountController.getAccount(id: list.accountID[i])
                        accountList.append(account)
                    }
                    watchListWithAccount2.updateValue(accountList, forKey: list)
                } catch {
                    print(error)
                }
            }
            let watchListWithAccount1 = watchListWithAccount2
            DispatchQueue.main.async {
                self.watchListWithAccount = watchListWithAccount1
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
