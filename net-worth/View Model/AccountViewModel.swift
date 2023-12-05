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
    @Published var accountTransactionListMultipleBrokerAccountsWithRange = [[AccountTransaction]]()
    @Published var accountTransactionListMultipleBrokerAccountsBelowRange = [[AccountTransaction]]()
    @Published var accountTransactionListMultipleNonBrokerAccountsWithRange = [[AccountTransaction]]()
    @Published var accountTransactionListMultipleNonBrokerAccountsBelowRange = [[AccountTransaction]]()
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
    
    func getAccountTransactionListForAllAccountsWithRange(accountList: [Account], range: String) async -> [AccountBroker] {
        var brokerList = [AccountBroker]()
        var accountTransactionListMultipleBrokerAccountsWithRange = [[AccountTransaction]]()
        var accountTransactionListMultipleNonBrokerAccountsWithRange = [[AccountTransaction]]()
        for account in accountList {
            if(account.accountType != "Broker") {
                let list = await accountTransactionController.getAccountTransactionListWithRange(accountID: account.id!, range: range)
                accountTransactionListMultipleNonBrokerAccountsWithRange.append(list)
            } else {
                let brokerAccountList = await brokerAccountController.getAccountInBrokerList(brokerID: account.id!)
                brokerList.append(contentsOf: brokerAccountList)
                for accountBroker in brokerAccountList {
                    let list = await brokerAccountController.getAccountTransactionsInBrokerAccountListWithRange(brokerID: account.id!, accountID: accountBroker.id!, range: range)
                    accountTransactionListMultipleBrokerAccountsWithRange.append(list)
                }
            }
        }
        let updatedAccountTransactionListMultipleBrokerAccountsWithRange = accountTransactionListMultipleBrokerAccountsWithRange
        let updatedAccountTransactionListMultipleNonBrokerAccountsWithRange = accountTransactionListMultipleNonBrokerAccountsWithRange
        DispatchQueue.main.async {
            self.accountTransactionListMultipleBrokerAccountsWithRange = [[AccountTransaction]]()
            self.accountTransactionListMultipleBrokerAccountsWithRange = updatedAccountTransactionListMultipleBrokerAccountsWithRange
            self.accountTransactionListMultipleNonBrokerAccountsWithRange = [[AccountTransaction]]()
            self.accountTransactionListMultipleNonBrokerAccountsWithRange = updatedAccountTransactionListMultipleNonBrokerAccountsWithRange
        }
        
        return brokerList
    }
    
    func getAccountTransactionListForAllAccountsBelowRange(accountList: [Account], range: String) async {
        var accountTransactionListMultipleBrokerAccountsBelowRange = [[AccountTransaction]]()
        var accountTransactionListMultipleNonBrokerAccountsBelowRange = [[AccountTransaction]]()
        for account in accountList {
            if(account.accountType != "Broker") {
                let list = await accountTransactionController.getAccountTransactionListBelowRange(accountID: account.id!, range: range)
                accountTransactionListMultipleNonBrokerAccountsBelowRange.append(list)
            } else {
                let brokerAccountList = await brokerAccountController.getAccountInBrokerList(brokerID: account.id!)
                for accountBroker in brokerAccountList {
                    let list = await brokerAccountController.getAccountTransactionsInBrokerAccountListBelowRange(brokerID: account.id!, accountID: accountBroker.id!, range: range)
                    accountTransactionListMultipleBrokerAccountsBelowRange.append(list)
                }
            }
        }
        let updatedAccountTransactionListMultipleBrokerAccountsBelowRange = accountTransactionListMultipleBrokerAccountsBelowRange
        let updatedAccountTransactionListMultipleNonBrokerAccountsBelowRange = accountTransactionListMultipleNonBrokerAccountsBelowRange
        DispatchQueue.main.async {
            self.accountTransactionListMultipleBrokerAccountsBelowRange = [[AccountTransaction]]()
            self.accountTransactionListMultipleBrokerAccountsBelowRange = updatedAccountTransactionListMultipleBrokerAccountsBelowRange
            self.accountTransactionListMultipleNonBrokerAccountsBelowRange = [[AccountTransaction]]()
            self.accountTransactionListMultipleNonBrokerAccountsBelowRange = updatedAccountTransactionListMultipleNonBrokerAccountsBelowRange
        }
    }
    
    func getAccountTransactionListMultipleAccountsWithRange(accountList: [Account], range: String) async {
        let list = await getAccountTransactionListMultipleNonBrokerAccountsWithRange(accountList: accountList, range: range)
        DispatchQueue.main.async {
            self.accountTransactionListMultipleNonBrokerAccountsWithRange = [[AccountTransaction]]()
            self.accountTransactionListMultipleNonBrokerAccountsWithRange = list
        }
    }
    
    private func getAccountTransactionListMultipleNonBrokerAccountsWithRange(accountList: [Account], range: String) async -> [[AccountTransaction]] {
        var transactionList = [[AccountTransaction]]()
        for account in accountList {
            if(account.accountType != "Broker") {
                let list = await accountTransactionController.getAccountTransactionListWithRange(accountID: account.id!, range: range)
                transactionList.append(list)
            }
        }
        return transactionList
    }
    
    func getAccountTransactionListMultipleAccountsBelowRange(accountList: [Account], range: String) async {
        let list = await getAccountTransactionListMultipleNonBrokerAccountsBelowRange(accountList: accountList, range: range)
        DispatchQueue.main.async {
            self.accountTransactionListMultipleNonBrokerAccountsBelowRange = [[AccountTransaction]]()
            self.accountTransactionListMultipleNonBrokerAccountsBelowRange = list
        }
    }
    
    private func getAccountTransactionListMultipleNonBrokerAccountsBelowRange(accountList: [Account], range: String) async -> [[AccountTransaction]] {
        var transactionList = [[AccountTransaction]]()
        for account in accountList {
            if(account.accountType != "Broker") {
                let list = await accountTransactionController.getAccountTransactionListBelowRange(accountID: account.id!, range: range)
                transactionList.append(list)
            }
        }
        return transactionList
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
        let accountList = await brokerAccountController.getAccountInBrokerList(brokerID: brokerID)
        DispatchQueue.main.async {
            self.accountsInBroker = accountList
        }
    }
    
    func getAccountTransactionsInBrokerAccountList(brokerID: String, accountID: String) async {
        let list = await brokerAccountController.getAccountTransactionsInBrokerAccountList(brokerID: brokerID, accountID: accountID)
        DispatchQueue.main.async {
            self.accountTransactionList = list
        }
    }
    
    func getAccountTransactionsOfAllAccountsInBroker(brokerID: String, range: String) async -> [AccountBroker] {
        let accountList = await brokerAccountController.getAccountInBrokerList(brokerID: brokerID)
        
        let accountTransactionListMultipleBrokerAccountsWithRange = await getAccountTransactionListMultipleBrokerAccountsWithRange(brokerID: brokerID, accountList: accountList, range: range)
        let accountTransactionListMultipleBrokerAccountsBelowRange = await getAccountTransactionListMultipleBrokerAccountsBelowRange(brokerID: brokerID, accountList: accountList, range: range)
        DispatchQueue.main.async {
            self.accountTransactionListMultipleBrokerAccountsWithRange = [[AccountTransaction]]()
            self.accountTransactionListMultipleBrokerAccountsWithRange = accountTransactionListMultipleBrokerAccountsWithRange
            self.accountTransactionListMultipleBrokerAccountsBelowRange = [[AccountTransaction]]()
            self.accountTransactionListMultipleBrokerAccountsBelowRange = accountTransactionListMultipleBrokerAccountsBelowRange
        }
        return accountList
    }
    
    private func getAccountTransactionListMultipleBrokerAccountsWithRange(brokerID: String, accountList: [AccountBroker], range: String) async -> [[AccountTransaction]] {
        var transactionList = [[AccountTransaction]]()
        for account in accountList {
            let list = await brokerAccountController.getAccountTransactionsInBrokerAccountListWithRange(brokerID: brokerID, accountID: account.id!, range: range)
            transactionList.append(list)
        }
        return transactionList
    }
    
    private func getAccountTransactionListMultipleBrokerAccountsBelowRange(brokerID: String, accountList: [AccountBroker], range: String) async -> [[AccountTransaction]] {
        var transactionList = [[AccountTransaction]]()
        for account in accountList {
            let list = await brokerAccountController.getAccountTransactionsInBrokerAccountListBelowRange(brokerID: brokerID, accountID: account.id!, range: range)
            transactionList.append(list)
        }
        return transactionList
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
