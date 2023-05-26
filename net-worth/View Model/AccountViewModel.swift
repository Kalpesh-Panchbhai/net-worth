//
//  AccountViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation
import FirebaseFirestore

class AccountViewModel: ObservableObject {
    
    
    var watchList = [Account]()
    var originalAccountList = [Account]()
    var accountController = AccountController()
    
    @Published var accountList = [Account]()
    @Published var accountListLoaded = false
    @Published var account = Account()
    @Published var accountTransactionList = [AccountTransaction]()
    @Published var accountTransactionListWithRange = [AccountTransaction]()
    @Published var accountTransactionListWithRangeMultipleAccounts = [[AccountTransaction]()]
    @Published var accountTransactionLastTransactionBelowRange = [[AccountTransaction]()]
    @Published var accountLastTwoTransactionList = [AccountTransaction]()
    @Published var totalBalance = Balance(currentValue: 0.0)
    @Published var grouping: Grouping = .accountType
    
    enum Grouping: String, CaseIterable, Identifiable {
        case accountType = "Account Type"
        case currency = "Currency"
        var id: String {
            self.rawValue
        }
    }
    
    var groupedAccount: [String: [Account]] {
        switch grouping {
        case .accountType:
            return Dictionary(grouping: accountList) {
                if($0.active) {
                    return $0.accountType
                } else {
                    return "Inactive Account"
                }
            }
        case .currency:
            return Dictionary(grouping: accountList) { $0.currency }
        }
    }
    
    var sectionHeaders: [String] {
        switch grouping {
        case .accountType:
            let array = Array(Set(accountList.map {
                if($0.active) {
                    return $0.accountType
                } else {
                    return "Inactive Account"
                }
            })).sorted(by: <)
            
            var returnList = array.filter { value in
                !value.elementsEqual("Inactive Account")
            }
            let inactiveAccount = array.filter { value in
                value.elementsEqual("Inactive Account")
            }
            if(!inactiveAccount.isEmpty) {
                returnList.append(inactiveAccount[0])
            }
            return returnList
        case .currency:
            return Array(Set(accountList.map{$0.currency})).sorted(by: <)
        }
    }
    
    func sectionContent(key: String, searchKeyword: String) -> [Account] {
        let data = groupedAccount[key] ?? []
        if searchKeyword.isEmpty {
            return data
        } else {
            return data.filter { value in
                value.accountName.lowercased().contains(searchKeyword.lowercased()) || value.accountType.lowercased().contains(searchKeyword.lowercased())
            }
        }
        
    }
    
    func sortAccountList(orderBy: String) {
        if(orderBy.elementsEqual(ConstantUtils.accountKeyAccountName)) {
            accountList
                .sort(by: {
                    $0.accountName < $1.accountName
                })
        } else if(orderBy.elementsEqual(ConstantUtils.accountKeyCurrentBalance)) {
            accountList
                .sort(by: {
                    $0.currentBalance < $1.currentBalance
                })
        }
    }
    
    func filterAccountList(filter: String) {
        accountList = originalAccountList
            .filter { account in
                account.accountType.lowercased().elementsEqual(filter.lowercased())
            }
    }
 
    func getAccount(id: String) async {
        do {
            let list = try await accountController.getAccount(id: id)
            DispatchQueue.main.async {
                self.account = list
            }
        } catch {
            print(error)
        }
    }
    
    func getAccountsForWatchList(accountID: [String]) async {
        do {
            watchList = [Account]()
            for i in 0..<accountID.count {
                let account = try await accountController.getAccount(id: accountID[i])
                watchList.append(account)
            }
            DispatchQueue.main.async {
                self.accountList = self.watchList
            }
        } catch {
            print(error)
        }
    }
    
    func getAccountList() async {
        do {
            let list = try await accountController.getAccountList()
            DispatchQueue.main.async {
                self.accountList = list
                self.originalAccountList = list
                self.accountListLoaded = true
            }
        } catch {
            print(error)
        }
    }
    
    func getTotalBalance(accountList: [Account]) async {
        do {
            let balance = try await accountController.fetchTotalBalance(accountList: accountList)
            DispatchQueue.main.async {
                self.totalBalance = balance
            }
        } catch {
            print(error)
        }
    }
    
    func getAccountTransactionList(id: String) async {
        do {
            let list = try await accountController.getAccountTransactionList(id: id)
            DispatchQueue.main.async {
                self.accountTransactionList = list
            }
        } catch {
            print(error)
        }
    }
    
    func getAccountTransactionListWithRange(id: String, range: String) async {
        do {
            let list = try await accountController.getAccountTransactionListWithRange(id: id, range: range)
            DispatchQueue.main.async {
                self.accountTransactionListWithRange = list
            }
        } catch {
            print(error)
        }
    }
    
    func getAccountTransactionListWithRangeMultipleAccounts(accountList: [Account], range: String) async {
        do {
            DispatchQueue.main.async {
                self.accountTransactionListWithRangeMultipleAccounts = [[AccountTransaction]()]
            }
            for account in accountList {
                let list = try await accountController.getAccountTransactionListWithRange(id: account.id!, range: range)
                DispatchQueue.main.async {
                    self.accountTransactionListWithRangeMultipleAccounts.append(list)
                }
            }
        } catch {
            print(error)
        }
    }
    
    func getAccountLastTransactionBelowRange(accountList: [Account], range: String) async {
        do {
            DispatchQueue.main.async {
                self.accountTransactionLastTransactionBelowRange = [[AccountTransaction]()]
            }
            for account in accountList {
                let list = try await accountController.getAccountLastTransactionBelowRange(id: account.id!, range: range)
                DispatchQueue.main.async {
                    self.accountTransactionLastTransactionBelowRange.append(list)
                }
            }
        } catch {
            print(error)
        }
    }
    
    func getLastTwoAccountTransactionList(id: String) async {
        do {
            let list = try await accountController.getLastTwoAccountTransactionList(id: id)
            DispatchQueue.main.async {
                self.accountLastTwoTransactionList = list
            }
        } catch {
            print(error)
        }
    }
}