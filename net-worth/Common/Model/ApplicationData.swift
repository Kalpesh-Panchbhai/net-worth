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
    var chartDataList: [String: [ChartData]]
    
    var dataLoading = false
    var lastUpdatedChartTimestamp: Date
    
    var symbolDataList = [String: [ChartData]]()
    
    private init() {
        data = Data()
        chartDataList = [String: [ChartData]]()
        lastUpdatedChartTimestamp = Date.now
    }
    
    public static func loadData(fetchLatest: Bool = false) async {
        shared.dataLoading = true
        print(Date.now)
        await fetchData()
        await CommonChartController().fetchChartData(fetchLatest: fetchLatest)
        print(Date.now)
        shared.dataLoading = false
    }
    
    public static func clear() {
        shared = ApplicationData()
        UserDefaults.standard.removeObject(forKey: "data")
        UserDefaults.standard.removeObject(forKey: "chartData")
    }
    
    private static func fetchData() async {
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
    }
    
    private static func loadIncomeData() async {
        let incomeList = await IncomeController().fetchLastestIncomeList()
        
        let newIncomeDataList = incomeList.map {
            return IncomeData(income: Income(id: $0.id!, amount: $0.amount, taxpaid: $0.taxpaid, creditedOn: $0.creditedOn, currency: $0.currency, type: $0.type, tag: $0.tag, deleted: $0.deleted))
        }
        
        var oldIncomeDataList = ApplicationData.shared.data.incomeDataList
        
        for incomeData in newIncomeDataList {
            
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
        var oldAccountDataList = ApplicationData.shared.data.accountDataList
        let accountList = await AccountController().fetchLastestAccountList()
        var newAccountDataList = accountList.map {
            return AccountData(account: $0, accountInBroker: [AccountInBrokerData](), accountTransaction: [AccountTransaction]())
        }
        
        for i in 0..<newAccountDataList.count {
            
            let accountContains = oldAccountDataList.contains(where: {
                return $0.account.id!.elementsEqual(newAccountDataList[i].account.id!)
            })
            
            if(!accountContains) {
                if(!newAccountDataList[i].account.deleted) {
                    if(newAccountDataList[i].account.accountType == ConstantUtils.brokerAccountType) {
                        var accountInbrokerList = await AccountInBrokerController().fetchLastestAccountListInBroker(brokerID: newAccountDataList[i].account.id!)
                        accountInbrokerList = accountInbrokerList.filter {
                            return !$0.deleted
                        }
                        
                        accountInbrokerList.sort(by: {
                            return $0.name < $1.name
                        })
                        for accountInBroker in accountInbrokerList {
                            var accountTransactionList = await AccountInBrokerController().fetchLastestAccountTransactionListInAccountInBroker(brokerID: newAccountDataList[i].account.id!, accountID: accountInBroker.id!)
                            accountTransactionList = accountTransactionList.filter {
                                return !$0.deleted
                            }
                            accountTransactionList.sort(by: {
                                return $0.timestamp > $1.timestamp
                            })
                            let accountInBrokerData = AccountInBrokerData(accountInBroker: accountInBroker, accountTransaction: accountTransactionList)
                            newAccountDataList[i].accountInBroker.append(accountInBrokerData)
                        }
                    } else {
                        var accountTransactionList = await AccountTransactionController().fetchLastestAccountTransactionList(accountID: newAccountDataList[i].account.id!)
                        accountTransactionList.sort(by: {
                            return $0.timestamp > $1.timestamp
                        })
                        newAccountDataList[i].accountTransaction = accountTransactionList
                    }
                    oldAccountDataList.append(newAccountDataList[i])
                }
            } else {
                
                if(!newAccountDataList[i].account.deleted) {
                    var oldAccount = oldAccountDataList.first(where: {
                        return $0.account.id!.elementsEqual(newAccountDataList[i].account.id!)
                    })!
                    oldAccount.account = newAccountDataList[i].account
                    
                    if(oldAccount.account.accountType == ConstantUtils.brokerAccountType) {
                        let oldAccountInBroker = oldAccount.accountInBroker
                        var accountInbrokerList = await AccountInBrokerController().fetchLastestAccountListInBroker(brokerID: newAccountDataList[i].account.id!)
                        
                        accountInbrokerList.sort(by: {
                            return $0.name < $1.name
                        })
                        for accountInBroker in accountInbrokerList {
                            if(!accountInBroker.deleted) {
                                var oldAccountTransactionList = oldAccountInBroker.first(where: {
                                    return $0.accountInBroker.id!.elementsEqual(accountInBroker.id!)
                                })?.accountTransaction ?? [AccountTransaction]()
                                var accountTransactionList = await AccountInBrokerController().fetchLastestAccountTransactionListInAccountInBroker(brokerID: newAccountDataList[i].account.id!, accountID: accountInBroker.id!)
                                oldAccountTransactionList.removeAll(where: { transaction in
                                    return accountTransactionList.contains(where: {
                                        return $0.id!.elementsEqual(transaction.id!)
                                    })
                                })
                                accountTransactionList.append(contentsOf: oldAccountTransactionList)
                                accountTransactionList = accountTransactionList.filter {
                                    return !$0.deleted
                                }
                                accountTransactionList.sort(by: {
                                    return $0.timestamp > $1.timestamp
                                })
                                let accountInBrokerData = AccountInBrokerData(accountInBroker: accountInBroker, accountTransaction: accountTransactionList)
                                
                                oldAccount.accountInBroker.removeAll(where: {
                                    return $0.accountInBroker.id!.elementsEqual(accountInBroker.id!)
                                })
                                oldAccount.accountInBroker.append(accountInBrokerData)
                            } else {
                                oldAccount.accountInBroker.removeAll(where: {
                                    return $0.accountInBroker.id!.elementsEqual(accountInBroker.id!)
                                })
                            }
                        }
                    } else {
                        var oldAccountTransactionList = oldAccount.accountTransaction
                        var newAccountTransactionList = await AccountTransactionController().fetchLastestAccountTransactionList(accountID: oldAccount.account.id!)
                        oldAccountTransactionList = oldAccountTransactionList.filter { transaction in
                            return !newAccountTransactionList.contains(where: {
                                return $0.id!.elementsEqual(transaction.id!)
                            })
                        }
                        newAccountTransactionList = newAccountTransactionList.filter {
                            return !$0.deleted
                        }
                        oldAccountTransactionList.append(contentsOf: newAccountTransactionList)
                        oldAccountTransactionList.sort(by: {
                            return $0.timestamp > $1.timestamp
                        })
                        oldAccount.accountTransaction = oldAccountTransactionList
                    }
                    
                    oldAccountDataList.removeAll(where: {
                        return $0.account.id!.elementsEqual(newAccountDataList[i].account.id!)
                    })
                    oldAccountDataList.append(oldAccount)
                } else {
                    oldAccountDataList.removeAll(where: {
                        return $0.account.id!.elementsEqual(newAccountDataList[i].account.id!)
                    })
                }
            }
        }
        
        oldAccountDataList.sort(by: {
            return $0.account.accountName < $1.account.accountName
        })
        shared.data.accountDataList = oldAccountDataList
        shared.data.accountDataListUpdatedDate = Date.now
    }
}
