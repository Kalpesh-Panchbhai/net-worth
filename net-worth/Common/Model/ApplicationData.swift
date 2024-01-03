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
                
                var newDataAvailable = false
                if(await UserController().isNewIncomeAvailable()) {
                    newDataAvailable = true
                    await loadIncomeData()
                }
                
                if(await UserController().isNewAccountAvailable()) {
                    newDataAvailable = true
                    await loadAccountData()
                }
                
                if(newDataAvailable) {
                    do {
                        let encoder = JSONEncoder()
                        
                        let data = try encoder.encode(shared.data)
                        
                        UserDefaults.standard.set(data, forKey: "data")
                        
                    } catch {
                        print("Unable to Encode Note (\(error))")
                    }
                }
            } catch {
                print("Unable to Decode Note (\(error))")
            }
        } else {
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
        let incomeList = await IncomeController().getIncomeList()
        
        let incomeDataList = incomeList.map {
            return IncomeData(income: Income(id: $0.id!, amount: $0.amount, taxpaid: $0.taxpaid, creditedOn: $0.creditedOn, currency: $0.currency, type: $0.type, tag: $0.tag, deleted: $0.deleted))
        }
        
        var oldIncomeDataList = ApplicationData.shared.data.incomeDataList
        
        for incomeData in incomeDataList {
            
            let incomeContains = oldIncomeDataList.contains(where: {
                return $0.income.id!.elementsEqual(incomeData.income.id!)
            })
            
            if(!incomeContains) {
                if(!incomeData.income.deleted) {
                    oldIncomeDataList.append(incomeData)
                }
            } else {
                oldIncomeDataList.removeAll(where: {
                    return $0.income.id!.elementsEqual(incomeData.income.id!)
                })
                if(!incomeData.income.deleted) {
                    oldIncomeDataList.append(incomeData)
                }
            }
        }
        
        oldIncomeDataList.sort(by: {
            return $0.income.creditedOn < $1.income.creditedOn
        })
        shared.data.incomeDataList = oldIncomeDataList
        shared.data.incomeDataListUpdatedDate = Date.now
    }
    
    private static func loadAccountData() async {
        let accountList = await AccountController().fetchLastestAccountList()
        var accountDataList = accountList.map {
            return AccountData(account: $0, accountInBroker: [AccountInBrokerData](), accountTransaction: [AccountTransaction]())
        }
        
        accountDataList.sort(by: {
            return $0.account.accountName < $1.account.accountName
        })
        
        for i in 0..<accountDataList.count {
            if(accountDataList[i].account.accountType == ConstantUtils.brokerAccountType) {
                var accountInbrokerList = await AccountInBrokerController().fetchLastestAccountListInBroker(brokerID: accountDataList[i].account.id!)
                
                accountInbrokerList.sort(by: {
                    return $0.name < $1.name
                })
                for accountInBroker in accountInbrokerList {
                    var accountTransactionList = await AccountInBrokerController().fetchLastestAccountTransactionListInAccountInBroker(brokerID: accountDataList[i].account.id!, accountID: accountInBroker.id!)
                    accountTransactionList.sort(by: {
                        return $0.timestamp > $1.timestamp
                    })
                    let accountInBrokerData = AccountInBrokerData(accountInBroker: accountInBroker, accountTransaction: accountTransactionList)
                    accountDataList[i].accountInBroker.append(accountInBrokerData)
                }
            } else {
                var accountTransactionList = await AccountTransactionController().fetchLastestAccountTransactionList(accountID: accountDataList[i].account.id!)
                accountTransactionList.sort(by: {
                    return $0.timestamp > $1.timestamp
                })
                accountDataList[i].accountTransaction = accountTransactionList
            }
        }
        shared.data.accountDataList = accountDataList
        shared.data.accountDataListUpdatedDate = Date.now
    }
}
