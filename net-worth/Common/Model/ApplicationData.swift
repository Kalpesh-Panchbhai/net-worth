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
    
    private init() {
        data = Data()
        chartDataList = [String: [ChartData]]()
    }
    
    public static func loadData() async {
        shared.dataLoading = true
        print(Date.now)
        await fetchData()
        await fetchChartData()
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
    
    private static func fetchChartData() async {
        if let chartData = UserDefaults.standard.data(forKey: "chartData") {
            do {
                let decoder = JSONDecoder()
                
                shared.chartDataList = try decoder.decode([String: [ChartData]].self, from: chartData)
            } catch {
                print("Unable to Decode Note (\(error))")
            }
        } else {
            await loadChartData()
            await generateChartDataForEachAccountType()
            await generateChartDataForEachWatchList()
            
            do {
                let encoder = JSONEncoder()
                
                let chartDataList = try encoder.encode(shared.chartDataList)
                
                UserDefaults.standard.set(chartDataList, forKey: "chartData")
                
            } catch {
                print("Unable to Encode Note (\(error))")
            }
        }
    }
    
    private static func loadChartData() async {
        var symbolDataList = [String: [ChartData]]()
        let accountDataList = shared.data.accountDataList
        for accountData in accountDataList {
            if(accountData.account.accountType.elementsEqual(ConstantUtils.brokerAccountType)) {
                let accountInBrokerList = accountData.accountInBroker
                for accountInBroker in accountInBrokerList {
                    if(accountInBroker.accountTransaction.count > 0) {
                        let symbol = accountInBroker.accountInBroker.symbol
                        if(!symbolDataList.contains(where: {
                            return $0.key.elementsEqual(symbol)
                        })) {
                            let symbolList = await FinanceController().getSymbolDetail(symbol: symbol, range: "5y")
                            
                            let rawSymbolConvertedToMap = convertRawDataToMap(symbol: symbolList)
                            
                            if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code) && !symbolDataList.contains(where: {
                                return $0.key.elementsEqual(symbolList.currency!)
                            })) {
                                let currencyList = await FinanceController().getCurrencyDetail(accountCurrency: SettingsController().getDefaultCurrency().code, range: "10y")
                                let rawCurrencyConvertedToMap = convertRawDataToMap(symbol: currencyList)
                                symbolDataList.updateValue(rawCurrencyConvertedToMap, forKey: symbolList.currency!)
                            }
                            
                            if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code)) {
                                let currencyData = symbolDataList.first(where: {
                                    return $0.key.elementsEqual(symbolList.currency!)
                                })!.value
                                
                                var chartDataList = [ChartData]()
                                for symbol in rawSymbolConvertedToMap {
                                    let data = currencyData.last(where: {
                                        return $0.date.removeTimeStamp() <= symbol.date.removeTimeStamp()
                                    })!
                                    
                                    chartDataList.append(ChartData(date: symbol.date.removeTimeStamp(), value: symbol.value * data.value))
                                }
                                
                                symbolDataList.updateValue(chartDataList, forKey: symbol)
                            } else {
                                symbolDataList.updateValue(rawSymbolConvertedToMap, forKey: symbol)
                            }
                        }
                        
                        let transactionList = accountInBroker.accountTransaction
                        let symbolData = symbolDataList.first(where: {
                            return $0.key.elementsEqual(symbol)
                        })!.value
                        
                        var startDate = transactionList.last!.timestamp.removeTimeStamp()
                        
                        let symbolStartDate = symbolData.first!.date.removeTimeStamp()
                        if(symbolStartDate > startDate) {
                            startDate = symbolStartDate
                        }
                        var chartData = [ChartData]()
                        while(startDate <= Date.now.removeTimeStamp()) {
                            let latestTransaction = transactionList.first(where: {
                                return $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
                            })!
                            let oldestSymbolData = symbolData.last(where: {
                                return $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
                            })!
                            chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance * oldestSymbolData.value))
                            startDate.addTimeInterval(86400)
                        }
                        shared.chartDataList.updateValue(chartData, forKey: accountInBroker.accountInBroker.id!)
                    }
                }
                let chartDataList = generateChartDataForOneBrokerAccount(accountData: accountData)
                shared.chartDataList.updateValue(chartDataList, forKey: accountData.account.id!)
            } else {
                let transactionList = accountData.accountTransaction
                var startDate = transactionList.last!.timestamp.removeTimeStamp()
                var chartData = [ChartData]()
                while(startDate <= Date.now.removeTimeStamp()) {
                    let latestTransaction = transactionList.first(where: {
                        return $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
                    })!
                    chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance))
                    startDate.addTimeInterval(86400)
                }
                shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
            }
        }
    }
    
    private static func generateChartDataForEachAccountType() async {
        let accountDataList = shared.data.accountDataList
        let accountDataListByAccountType = Dictionary(grouping: accountDataList) {
            if($0.account.active) {
                return $0.account.accountType
            } else {
                return "Inactive Account"
            }
        }
        
        for (accountType, accountDataList) in accountDataListByAccountType {
            if(accountType.elementsEqual(ConstantUtils.brokerAccountType) || accountType.elementsEqual("Inactive Account")) {
                if(accountType.elementsEqual("Inactive Account")) {
                    let chartDataListResult = await generateChartdataForMixedAccounts(accountDataList: accountDataList)
                    shared.chartDataList.updateValue(chartDataListResult, forKey: "Inactive Account")
                } else {
                    let chartDataListResult = await generateChartDataForMultipleBrokerAccounts(accountDataList: accountDataList)
                    shared.chartDataList.updateValue(chartDataListResult, forKey: ConstantUtils.brokerAccountType)
                }
            } else {
                let chartDataListResult = await generateChartDataForMultipleNonBrokerAccount(accountDataList: accountDataList)
                shared.chartDataList.updateValue(chartDataListResult, forKey: accountType)
            }
        }
    }
    
    private static func generateChartDataForEachWatchList() async {
        let watchList = await WatchController().getAllWatchList()
        for watch in watchList {
            let chartDataListResult = generateChartDataForWatchAccount(accountIDList: watch.accountID)
            shared.chartDataList.updateValue(chartDataListResult, forKey: watch.id!)
        }
    }
    
    private static func generateChartDataForWatchAccount(accountIDList: [String]) -> [ChartData] {
        var chartDataListResult = [ChartData]()
        var dummy = [[ChartData]]()
        for accountID in accountIDList {
            let chartData = shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountID)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = dummy.min(by: {
            return $0.min(by: {
                return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
            })!.date <= $1.min(by: {
                return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
            })!.date
        })!.first!.date.removeTimeStamp()
        while(startDate <= Date.now) {
            var totalValue = 0.0
            for d in dummy {
                totalValue += d.last(where: {
                    return $0.date.removeTimeStamp() <= startDate
                })?.value ?? 0.0
            }
            chartDataListResult.append(ChartData(date: startDate.removeTimeStamp(), value: totalValue))
            startDate.addTimeInterval(86400)
        }
        
        return chartDataListResult
    }
    
    private static func generateChartDataForMultipleNonBrokerAccount(accountDataList: [AccountData]) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        var dummy = [[ChartData]]()
        for accountData in accountDataList {
            let chartData = shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountData.account.id!)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = dummy.min(by: {
            return $0.min(by: {
                return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
            })!.date <= $1.min(by: {
                return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
            })!.date
        })!.first!.date.removeTimeStamp()
        while(startDate <= Date.now) {
            var totalValue = 0.0
            for d in dummy {
                totalValue += d.last(where: {
                    return $0.date.removeTimeStamp() <= startDate
                })?.value ?? 0.0
            }
            chartDataListResult.append(ChartData(date: startDate.removeTimeStamp(), value: totalValue))
            startDate.addTimeInterval(86400)
        }
        
        return chartDataListResult
    }
    
    private static func generateChartdataForMixedAccounts(accountDataList: [AccountData]) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        
        var nonBrokerAccountList = [AccountData]()
        var brokerAccountList = [AccountData]()
        
        for accountData in accountDataList {
            if(accountData.account.accountType.elementsEqual(ConstantUtils.brokerAccountType)) {
                brokerAccountList.append(accountData)
            } else {
                nonBrokerAccountList.append(accountData)
            }
        }
        
        let chartDataForNonBrokerAccountList = await generateChartDataForMultipleNonBrokerAccount(accountDataList: nonBrokerAccountList)
        let chartDataForBrokerAccountList = await generateChartDataForMultipleBrokerAccounts(accountDataList: brokerAccountList)
        var startDate = getStartDate(chartDataForNonBrokerAccountList: chartDataForNonBrokerAccountList, chartDataForBrokerAccountList: chartDataForBrokerAccountList)
        
        while(startDate <= Date.now) {
            
            var totalValue = 0.0
            
            let transaction1 = chartDataForBrokerAccountList.last(where: {
                return $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
            })
            
            if(transaction1 != nil) {
                totalValue += transaction1!.value
            }
            
            let transaction2 = chartDataForNonBrokerAccountList.last(where: {
                return $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
            })
            
            if(transaction2 != nil) {
                totalValue += transaction2!.value
            }
            chartDataListResult.append(ChartData(date: startDate.removeTimeStamp(), value: totalValue))
            startDate.addTimeInterval(86400)
        }
        return chartDataListResult
    }
    
    private static func getStartDate(chartDataForNonBrokerAccountList: [ChartData], chartDataForBrokerAccountList: [ChartData]) -> Date {
        if(chartDataForBrokerAccountList.count > 0 && chartDataForNonBrokerAccountList.count > 0) {
            return (chartDataForBrokerAccountList.first!.date.removeTimeStamp() >= chartDataForNonBrokerAccountList.first!.date.removeTimeStamp()) ? chartDataForNonBrokerAccountList.first!.date : chartDataForBrokerAccountList.first!.date
        } else if(chartDataForBrokerAccountList.count > 0) {
            return chartDataForBrokerAccountList.first!.date.removeTimeStamp()
        } else if(chartDataForNonBrokerAccountList.count > 0) {
            return chartDataForNonBrokerAccountList.first!.date.removeTimeStamp()
        }
        return Date.now.removeTimeStamp().addingTimeInterval(86400)
    }
    
    private static func generateChartDataForOneBrokerAccount(accountData: AccountData) -> [ChartData] {
        var chartDataListResult = [ChartData]()
        var dummy = [[ChartData]]()
        for accountInBroker in accountData.accountInBroker {
            let chartData = shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountInBroker.accountInBroker.id!)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = dummy.min(by: {
            return $0.min(by: {
                return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
            })!.date <= $1.min(by: {
                return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
            })!.date
        })!.first!.date.removeTimeStamp()
        while(startDate <= Date.now) {
            var totalValue = 0.0
            for d in dummy {
                totalValue += d.last(where: {
                    return $0.date.removeTimeStamp() <= startDate
                })?.value ?? 0.0
            }
            chartDataListResult.append(ChartData(date: startDate.removeTimeStamp(), value: totalValue))
            startDate.addTimeInterval(86400)
        }
        return chartDataListResult
    }
    
    private static func generateChartDataForMultipleBrokerAccounts(accountDataList: [AccountData]) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        var dummy = [[ChartData]]()
        for accountInBroker in accountDataList {
            let chartData = shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountInBroker.account.id!)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = dummy.min(by: {
            return $0.min(by: {
                return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
            })!.date <= $1.min(by: {
                return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
            })!.date
        })!.first!.date.removeTimeStamp()
        while(startDate <= Date.now) {
            var totalValue = 0.0
            for d in dummy {
                totalValue += d.last(where: {
                    return $0.date.removeTimeStamp() <= startDate
                })?.value ?? 0.0
            }
            chartDataListResult.append(ChartData(date: startDate.removeTimeStamp(), value: totalValue))
            startDate.addTimeInterval(86400)
        }
        return chartDataListResult
    }
    
    private static func convertRawDataToMap(symbol: FinanceDetailModel) -> [ChartData] {
        var returnData = [ChartData]()
        let timestampEpochList = symbol.timestamp
        let valueAtTimestampList = symbol.valueAtTimestamp
        
        for i in 0..<timestampEpochList.count {
            let date = convertEpochToDate(epochTime: Double(timestampEpochList[i]!))
            let value = valueAtTimestampList[i] ?? nil
            if(value != nil) {
                returnData.append(ChartData(date: date.removeTimeStamp(), value: value!))
            }
        }
        
        return returnData
    }
    
    private static func convertEpochToDate(epochTime: Double) -> Date {
        let date = Date(timeIntervalSince1970: TimeInterval(floatLiteral: epochTime))
        return date
    }
}
