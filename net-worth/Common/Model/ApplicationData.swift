//
//  ApplicationData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/06/23.
//

import Foundation

struct ApplicationData: Codable {
    
    static var shared = ApplicationData()
    
    var data: Data
    
    var dataLoading = false
    
    private init() {
        data = Data()
    }
    
    public static func loadData() async {
        shared.dataLoading = true
        if let data = UserDefaults.standard.data(forKey: "data") {
            do {
                let decoder = JSONDecoder()
                
                shared.data = try decoder.decode(Data.self, from: data)
                
                if(await UserController().isNewIncomeAvailable()) {
                    await loadIncomeData()
                }
                
                if(await UserController().isNewAccountAvailable()) {
                    await loadAccountData()
                }
                
                await loadUserData()
                
                do {
                    let encoder = JSONEncoder()
                    
                    let data = try encoder.encode(shared.data)
                    
                    UserDefaults.standard.set(data, forKey: "data")
                    
                } catch {
                    print("Unable to Encode Note (\(error))")
                }
            } catch {
                print("Unable to Decode Note (\(error))")
            }
        }else {
            await loadUserData()
            await loadIncomeData()
            await loadAccountData()
            
            do {
                let encoder = JSONEncoder()
                
                let data = try encoder.encode(shared.data)
                
                UserDefaults.standard.set(data, forKey: "data")
                
            } catch {
                print("Unable to Encode Note (\(error))")
            }
        }
        shared.dataLoading = false
    }
    
    public static func clear() {
        shared = ApplicationData()
        UserDefaults.standard.removeObject(forKey: "data")
    }
    
    private static func loadIncomeData() async {
        let incomeDataList = await IncomeController().getIncomeList()
        shared.data.incomeDataList = incomeDataList.map {
            return IncomeData(income: Income(id: $0.id!, amount: $0.amount, taxpaid: $0.taxpaid, creditedOn: $0.creditedOn, currency: $0.currency, type: $0.type, tag: $0.tag))
        }
    }
    
    private static func loadAccountData() async {
        let accountList = await AccountController().getAccountDataList()
        var accountDataList = accountList.map {
            return AccountData(account: $0, accountInBroker: [AccountInBrokerData](), accountTransaction: [AccountTransaction]())
        }
        
        for i in 0..<accountDataList.count {
            if(accountDataList[i].account.accountType == ConstantUtils.brokerAccountType) {
                let accountInbrokerList = await AccountInBrokerController().getAccountListInBroker(brokerID: accountDataList[i].account.id!)
                
                for accountInBroker in accountInbrokerList {
                    let accountTransaction = await AccountInBrokerController().getAccountTransactionListInAccountInBroker(brokerID: accountDataList[i].account.id!, accountID: accountInBroker.id!)
                    let accountInBrokerData = AccountInBrokerData(accountInBroker: accountInBroker, accountTransaction: accountTransaction)
                    accountDataList[i].accountInBroker.append(accountInBrokerData)
                }
            } else {
                let accountTransaction = await AccountTransactionController().getAccountTransactionDataList(accountID: accountDataList[i].account.id!)
                accountDataList[i].accountTransaction = accountTransaction
            }
        }
        shared.data.accountDataList = accountDataList
    }
    
    private static func loadUserData() async {
        let user = await UserController().getCurrentUser()
        shared.data.userData = user
        shared.data.incomeDataListUpdatedDate = user.incomeDataUpdatedDate
        shared.data.accountDataListUpdatedDate = user.accountDataUpdatedDate
    }
}
