//
//  AccountViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation

class AccountViewModel: ObservableObject {
    
    var watchList = [AccountRestModel]()
    var originalAccountList = [AccountRestModel]()
    var accountController = AccountController()
    var accountTransactionController = AccountTransactionController()
    var accountInBrokerController = AccountInBrokerController()
    
    @Published var accountList = [AccountRestModel]()
    @Published var accountListLoaded = false
    @Published var account = AccountRestModel()
    @Published var totalBalance = AccountValue()
    @Published var chartDataList = [ChartData]()
    @Published var grouping: Grouping = .accountType
    
    @Published var accountsInBroker = [AccountInBrokerRestModel]()
    @Published var accountBroker = AccountInBrokerRestModel()
    
    @Published var accountTransactionList = [AccountTransactionRestModel]()
    
    enum Grouping: String, CaseIterable, Identifiable {
        case accountType = "Account Type"
        case currency = "Currency"
        var id: String {
            self.rawValue
        }
    }
    
    var groupedAccount: [String: [AccountRestModel]] {
        switch grouping {
        case .accountType:
            return Dictionary(grouping: accountList) {
                if($0.active) {
                    return $0.type
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
                    return $0.type
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
    
    func sectionContent(key: String, searchKeyword: String) -> [AccountRestModel] {
        let data = groupedAccount[key] ?? []
        if searchKeyword.isEmpty {
            return data
        } else {
            return data.filter { value in
                value.name.lowercased().contains(searchKeyword.lowercased()) || value.type.lowercased().contains(searchKeyword.lowercased())
            }
        }
    }
    
    func filterAccountList(filter: String) {
        accountList = originalAccountList
            .filter { account in
                account.type.lowercased().elementsEqual(filter.lowercased())
            }
    }
    
    func getAccount(id: Int) async {
        let account = accountList.first(where: {
            return $0.id == id
        }) ?? AccountRestModel()
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
    
    func getTotalBalance(accountList: [AccountRestModel]) async {
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
    
    func getAccountTransactionList(accountID: Int, type: String) async {
        let list = await accountTransactionController.getAccountTransactionList(accountID: accountID, type: type)
        DispatchQueue.main.async {
            self.accountTransactionList = list
        }
    }
    
    func getChartDataList(id: Any, type: String) async {
        let list = await accountController.getChartDataList(id: id, type: type)
        DispatchQueue.main.async {
            self.chartDataList = list
        }
    }
}
