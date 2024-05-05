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
    var accountTransactionController = AccountTransactionController()
    var accountInBrokerController = AccountInBrokerController()
    
    @Published var accountList = [Account]()
    @Published var accountListLoaded = false
    @Published var account = Account()
    @Published var accountTransactionList = [AccountTransaction]()
    @Published var accountLastTwoTransactionList = [AccountTransaction]()
    @Published var accountOneDayChange = Balance()
    @Published var totalBalance = Balance(currentValue: 0.0)
    @Published var grouping: Grouping = .accountType
    
    @Published var accountsInBroker = [AccountInBroker]()
    @Published var accountBroker = AccountInBroker()
    @Published var accountBrokerCurrentBalance = Balance(currentValue: 0.0, previousDayValue: 0.0)
    
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
    
    func filterAccountList(filter: String) {
        accountList = originalAccountList
            .filter { account in
                account.accountType.lowercased().elementsEqual(filter.lowercased())
            }
    }
    
    func getAccount(id: String) async {
        let account = accountList.first(where: {
            return $0.id.elementsEqual(id)
        }) ?? Account()
        DispatchQueue.main.async {
            self.account = account
        }
    }
    
    func getAccountsForWatchList(accountID: [String]) async {
        watchList = [Account]()
//        let chartDataList = ApplicationData.shared.chartDataList
//        for i in 0..<accountID.count {
//            let currentBalance = chartDataList.first(where: {
//                return $0.key.elementsEqual(accountID[i])
//            })?.value.last?.value
//            var account = await accountController.getAccount(id: accountID[i])
//            account.currentBalance = currentBalance ?? 0.0
//            watchList.append(account)
//        }
        DispatchQueue.main.async {
            self.accountList = self.watchList
        }
    }
    
    func getAccountList() async {
        let list = await accountController.getAccountList()
        DispatchQueue.main.async {
            self.accountList = list
            self.originalAccountList = list
            self.accountListLoaded = true
        }
    }
    
    func getTotalBalance(accountList: [Account]) async {
        let balance = await accountController.calculateTotalBalance(accountList: accountList)
        DispatchQueue.main.async {
            self.totalBalance = balance
        }
    }
    
    func getAccountTransactionList(id: String) async {
        let list = await accountTransactionController.getTransactionList(accountId: id)
        DispatchQueue.main.async {
            self.accountTransactionList = list
        }
    }
    
    func getBrokerAccount(brokerID: String, accountID: String) async {
        let accountBroker = accountInBrokerController.getAccountInBroker(brokerID: brokerID, accountID: accountID)
        DispatchQueue.main.async {
            self.accountBroker = accountBroker
        }
    }
    
    func getAccountInBrokerList(brokerID: String) async {
        let accountList = accountInBrokerController.getAccountListInBroker(brokerID: brokerID)
        DispatchQueue.main.async {
            self.accountsInBroker = accountList
        }
    }
    
    func getAccountTransactionsInBrokerAccountList(brokerID: String, accountID: String) async {
        let list = accountInBrokerController.getAccountTransactionListInAccountInBroker(brokerID: brokerID, accountID: accountID)
        DispatchQueue.main.async {
            self.accountTransactionList = list
        }
    }
    
    func getCurrentBalanceOfAnAccountInBroker(accountBroker: AccountInBroker) async {
        let accountBrokerCurrentBalance = await accountInBrokerController.getCurrentBalanceOfAnAccountInBroker(accountBroker: accountBroker)
        DispatchQueue.main.async {
            self.accountBrokerCurrentBalance = accountBrokerCurrentBalance
        }
    }
    
    func getCurrentBalanceOfAllAccountsInABroker(accountBrokerList: [AccountInBroker]) async {
        let accountBrokerCurrentBalance = await accountInBrokerController.getCurrentBalanceOfAllAccountsInABroker(accountBrokerList: accountBrokerList)
        DispatchQueue.main.async {
            self.accountBrokerCurrentBalance = accountBrokerCurrentBalance
        }
    }
    
}
