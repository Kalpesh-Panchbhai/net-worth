//
//  AccountViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation
import FirebaseFirestore

class AccountViewModel: ObservableObject {
    
    @Published var accountList = [Account]()
    @Published var account = Account()
    @Published var accountTransactionList = [AccountTransaction]()
    @Published var accountTransactionListWithRange = [AccountTransaction]()
    @Published var accountLastTwoTransactionList = [AccountTransaction]()
    @Published var totalBalance = BalanceModel(currentValue: 0.0)
    @Published var grouping: Grouping = .accountType
    
    var watchList = [Account]()
    var originalAccountList = [Account]()
    private var accountController = AccountController()
    
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
            return Dictionary(grouping: accountList) { $0.accountType }
        case .currency:
            return Dictionary(grouping: accountList) { $0.currency }
        }
    }
    
    var sectionHeaders: [String] {
        switch grouping {
        case .accountType:
            return Array(Set(accountList.map{$0.accountType})).sorted(by: <)
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
    
    func resetAccountList() {
        accountList = originalAccountList
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
