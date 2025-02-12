//
//  AccountViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation

class AccountViewModel: ObservableObject {
    
    var watchList = [Account]()
    var originalAccountList = [Account]()
    var accountController = AccountController()
    var accountInBrokerController = AccountInBrokerController()
    
    @Published var accountList = [Account]()
    @Published var accountListLoaded = false
    @Published var account = Account()
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
    
    func getAccount(id: Int) async {
        let account = accountList.first(where: {
            return $0.id == id
        }) ?? Account()
        DispatchQueue.main.async {
            self.account = account
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
    
    func getAccountInBrokerList(brokerID: Int) async {
        let accountList = await accountInBrokerController.getAccountListInBroker(brokerID: brokerID)
        DispatchQueue.main.async {
            self.accountsInBroker = accountList
        }
    }
    
}
