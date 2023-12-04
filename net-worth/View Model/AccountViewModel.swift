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
    var brokerAccountController = BrokerAccountController()
    
    @Published var accountList = [Account]()
    @Published var accountListLoaded = false
    @Published var account = Account()
    @Published var accountTransactionList = [AccountTransaction]()
    @Published var accountTransactionListWithRange = [AccountTransaction]()
    @Published var accountTransactionListBelowRange = [AccountTransaction]()
    @Published var accountTransactionListWithRangeMultipleAccounts = [[AccountTransaction]]()
    @Published var accountTransactionLastTransactionBelowRange = [[AccountTransaction]]()
    @Published var accountLastTwoTransactionList = [AccountTransaction]()
    @Published var accountOneDayChange = Balance()
    @Published var totalBalance = Balance(currentValue: 0.0)
    @Published var grouping: Grouping = .accountType
    
    @Published var accountsInBroker = [AccountBroker]()
    @Published var accountBroker = AccountBroker()
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
        let list = accountController.getAccount(id: id)
        DispatchQueue.main.async {
            self.account = list
        }
    }
    
    func getAccountsForWatchList(accountID: [String]) async {
        watchList = [Account]()
        for i in 0..<accountID.count {
            let account = accountController.getAccount(id: accountID[i])
            watchList.append(account)
        }
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
        let balance = await accountController.fetchTotalBalance(accountList: accountList)
        DispatchQueue.main.async {
            self.totalBalance = balance
        }
    }
    
    func getAccountTransactionList(id: String) {
        let list = accountTransactionController.getAccountTransactionList(accountID: id)
        DispatchQueue.main.async {
            self.accountTransactionList = list
        }
    }
    
    func getAccountTransactionListWithRange(id: String, range: String) async {
        let list = await accountTransactionController.getAccountTransactionListWithRange(accountID: id, range: range)
        DispatchQueue.main.async {
            self.accountTransactionListWithRange = list
        }
    }
    
    func getAccountTransactionListWithRangeMultipleAccounts(accountList: [Account], range: String) async {
        DispatchQueue.main.async {
            self.accountTransactionListWithRangeMultipleAccounts = [[AccountTransaction]]()
        }
        for account in accountList {
            let list = await accountTransactionController.getAccountTransactionListWithRange(accountID: account.id!, range: range)
            DispatchQueue.main.async {
                self.accountTransactionListWithRangeMultipleAccounts.append(list)
            }
        }
    }
    
    func getAccountLastTransactionBelowRange(accountList: [Account], range: String) async {
        DispatchQueue.main.async {
            self.accountTransactionLastTransactionBelowRange = [[AccountTransaction]]()
        }
        for account in accountList {
            let list = await accountTransactionController.getAccountLastTransactionBelowRange(accountID: account.id!, range: range)
            DispatchQueue.main.async {
                self.accountTransactionLastTransactionBelowRange.append(list)
            }
        }
    }
    
    func getLastTwoAccountTransactionList(id: String) async {
        let list = await accountTransactionController.getLastTwoAccountTransactionList(accountID: id)
        DispatchQueue.main.async {
            self.accountLastTwoTransactionList = list
        }
    }
    
    func getAccountLastOneDayChange(id: String) async {
        let oneDayChange = await accountTransactionController.getAccountLastOneDayChange(accountID: id)
        DispatchQueue.main.async {
            self.accountOneDayChange = oneDayChange
        }
    }
    
    func getBrokerAccount(brokerID: String, accountID: String) async {
        let accountBroker = await brokerAccountController.getBrokerAccount(brokerID: brokerID, accountID: accountID)
        DispatchQueue.main.async {
            self.accountBroker = accountBroker
        }
    }
    
    func getAccountInBrokerList(brokerID: String) async {
        let list = await brokerAccountController.getAccountInBrokerList(brokerID: brokerID)
        DispatchQueue.main.async {
            self.accountsInBroker = list
        }
    }
    
    func getAccountTransactionsInBrokerAccountList(brokerID: String, accountID: String) async {
        let list = await brokerAccountController.getAccountTransactionsInBrokerAccountList(brokerID: brokerID, accountID: accountID)
        DispatchQueue.main.async {
            self.accountTransactionList = list
        }
    }
    
    func getAccountTransactionsInBrokerAccountList(brokerID: String, accountID: String, range: String) async {
        let accountTransactionListWithRange = await brokerAccountController.getAccountTransactionsInBrokerAccountListWithRange(brokerID: brokerID, accountID: accountID, range: range)
        let accountTransactionListBelowRange = await brokerAccountController.getAccountTransactionsInBrokerAccountListBelowRange(brokerID: brokerID, accountID: accountID, range: range)
        DispatchQueue.main.async {
            self.accountTransactionListWithRange = accountTransactionListWithRange
            self.accountTransactionListBelowRange = accountTransactionListBelowRange
        }
    }
    
    func getBrokerAccountCurrentBalance(accountBroker: AccountBroker) async {
        let accountBrokerCurrentBalance = await brokerAccountController.getBrokerAccountCurrentBalance(accountBroker: accountBroker)
        DispatchQueue.main.async {
            self.accountBrokerCurrentBalance = accountBrokerCurrentBalance
        }
    }
    
    func getBrokerAllAccountCurrentBalance(accountBrokerList: [AccountBroker]) async {
        var Balance = Balance(currentValue: 0.0, previousDayValue: 0.0)
        for accountBroker in accountBrokerList {
            let accountBrokerCurrentBalance = await brokerAccountController.getBrokerAccountCurrentBalance(accountBroker: accountBroker)
            Balance.currentValue = Balance.currentValue + accountBrokerCurrentBalance.currentValue
            Balance.previousDayValue = Balance.previousDayValue + accountBrokerCurrentBalance.previousDayValue
        }
        let newBalance = Balance
        DispatchQueue.main.async {
            self.accountBrokerCurrentBalance = newBalance
        }
    }
    
}
