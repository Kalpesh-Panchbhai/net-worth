//
//  ApplicationData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/06/23.
//

import Foundation

struct ApplicationData: Codable {
    
    static var shared = ApplicationData()
    
    var userId: String
    
    var data: Data2
    var chartDataList: [String: [ChartData]]
    
    var dataLoading = false
    var chartLastUpdated: Date
    
    var symbolDataList = [String: [ChartData]]()
    var totalAccount = Int()
    
    private init() {
        userId = ""
        data = Data2()
        chartDataList = [String: [ChartData]]()
        chartLastUpdated = Date.now
    }
    
    public static func loadData() async {
        shared.dataLoading = true
        await UserController().addCurrentUser()
        shared.dataLoading = false
        await countTotalAccount()
    }
    
    public static func countTotalAccount() async {
        var totalAccount = shared.data.accountDataList.count
        totalAccount += Dictionary(grouping: shared.data.accountDataList) {
            if($0.account.active) {
                return $0.account.accountType
            } else {
                return "Inactive Account"
            }
        }.count
        totalAccount += await WatchController().getAllWatchList().count
        shared.totalAccount = totalAccount
    }
    
    public static func clear() {
        shared = ApplicationData()
        UserDefaults.standard.removeObject(forKey: "data")
        UserDefaults.standard.removeObject(forKey: "chartData")
        UserDefaults.standard.removeObject(forKey: ConstantUtils.chartLastUpdated)
    }
    
    public static func fetchChartData(fetchLatest: Bool) async {
        if let chartData = UserDefaults.standard.data(forKey: "chartData") {
            do {
                let decoder = JSONDecoder()
                
                ApplicationData.shared.chartDataList = try decoder.decode([String: [ChartData]].self, from: chartData)
                ApplicationData.shared.chartLastUpdated = UserDefaults.standard.object(forKey: ConstantUtils.chartLastUpdated) as! Date
            } catch {
                print("Unable to Decode Note (\(error))")
            }
        }
        
        if(fetchLatest) {
            print(Date.now)
            await fetchChartData()
            print(Date.now)
        }
    }
    
    private static func fetchChartData() async {
        removeChartDataForLastUpdatedTime()
        let date = await loadChartData()
        await self.generateChartDataForEachAccountType(isRefreshOperation: true,refreshChartStartDate: date)
        await self.generateChartDataForEachWatchList(isRefreshOperation: true,refreshChartStartDate: date)
        
        updateChartData()
    }
    
    public static func removeChartDataForLastUpdatedTime() {
        let chartLastUpdatedTime = ApplicationData.shared.chartLastUpdated.removeTimeStamp()
        ApplicationData.shared.chartDataList = ApplicationData.shared.chartDataList.mapValues {
            return $0.filter {
                $0.date.removeTimeStamp() != chartLastUpdatedTime
            }
        }
    }
    
    public static func updateChartData() {
        do {
            let encoder = JSONEncoder()
            
            let chartDataList = try encoder.encode(ApplicationData.shared.chartDataList)
            
            UserDefaults.standard.set(chartDataList, forKey: "chartData")
            
        } catch {
            print("Unable to Encode Note (\(error))")
        }
        UserDefaults.standard.set(Date.now, forKey: ConstantUtils.chartLastUpdated)
    }
    
    public static func loadChartData() async -> Date {
        let accountDataList = ApplicationData.shared.data.accountDataList
        var lastUpdatedDate = Date().removeTimeStamp()
        for accountData in accountDataList {
            if(accountData.account.accountType.elementsEqual(ConstantUtils.brokerAccountType)) {
                let date = await loadChartDataForBrokerAccount(accountData: accountData)
                if(date < lastUpdatedDate) {
                    lastUpdatedDate = date
                }
            } else {
                let date = await loadChartDataForNonBrokerAccount(accountData: accountData)
                if(date < lastUpdatedDate) {
                    lastUpdatedDate = date
                }
            }
        }
        return lastUpdatedDate
    }
    
    public static func loadChartDataForBrokerAccount(accountData: AccountData) async -> Date {
        let accountInBrokerList = accountData.accountInBroker
        var lastUpdatedDate = Date().removeTimeStamp()
        for accountInBroker in accountInBrokerList {
            if(isAccountAvailableInChartDataList(accountID: accountInBroker.accountInBroker.id!)) {
                let date = await self.loadChartDataForExistingBrokerAccount(accountInBroker: accountInBroker)
                if(date < lastUpdatedDate) {
                    lastUpdatedDate = date
                }
            } else {
                let date = await self.loadChartDataForNonExistingBrokerAccount(accountInBroker: accountInBroker)
                if(date < lastUpdatedDate) {
                    lastUpdatedDate = date
                }
            }
        }
        let chartDataList = generateChartDataForOneBrokerAccount(accountData: accountData, isRefreshOperation: true, refreshChartStartDate: lastUpdatedDate)
        ApplicationData.shared.chartDataList.updateValue(chartDataList, forKey: accountData.account.id!)
        return lastUpdatedDate
    }
    
    public static func loadChartDataForExistingBrokerAccount(accountInBroker: AccountInBrokerData) async -> Date {
        if(accountInBroker.accountTransaction.count > 0) {
            let symbol = accountInBroker.accountInBroker.symbol
            let transactionList = accountInBroker.accountTransaction
            let index = transactionList.lastIndex(where: {
                return $0.createdDate >= ApplicationData.shared.chartLastUpdated
            })
            if(index != nil) {
                let newTransactionList = transactionList[0...index!]
                var chartData = ApplicationData.shared.chartDataList.first(where: {
                    return $0.key.elementsEqual(accountInBroker.accountInBroker.id!)
                })!.value
                chartData.removeAll(where: {
                    return $0.date.removeTimeStamp() >= newTransactionList.last!.timestamp
                })
                if(!chartData.isEmpty) {
                    chartData.removeLast()
                }
                var startDate = Date.now
                if(chartData.isEmpty) {
                    startDate = newTransactionList.last!.timestamp.removeTimeStamp()
                } else {
                    startDate = chartData.last!.date.addingTimeInterval(86400).removeTimeStamp()
                }
                
                if(!ApplicationData.shared.symbolDataList.contains(where: {
                    return $0.key.elementsEqual(symbol)
                })) {
                    let symbolList = await FinanceController().getSymbolDetail(symbol: symbol, range: "10y")
                    
                    let rawSymbolConvertedToMap = ChartController().convertRawDataToMap(symbol: symbolList)
                    
                    if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code) && !ApplicationData.shared.symbolDataList.contains(where: {
                        return $0.key.elementsEqual(symbolList.currency!)
                    })) {
                        let currencyList = await FinanceController().getCurrencyDetail(accountCurrency: SettingsController().getDefaultCurrency().code, range: "10y")
                        let rawCurrencyConvertedToMap = ChartController().convertRawDataToMap(symbol: currencyList)
                        ApplicationData.shared.symbolDataList.updateValue(rawCurrencyConvertedToMap, forKey: symbolList.currency!)
                    }
                    
                    if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code)) {
                        let currencyData = ApplicationData.shared.symbolDataList.first(where: {
                            return $0.key.elementsEqual(symbolList.currency!)
                        })!.value
                        
                        var chartDataList = [ChartData]()
                        for symbol in rawSymbolConvertedToMap {
                            let data = currencyData.last(where: {
                                return $0.date.removeTimeStamp() <= symbol.date.removeTimeStamp()
                            })!
                            
                            chartDataList.append(ChartData(date: symbol.date.removeTimeStamp(), value: symbol.value * data.value))
                        }
                        
                        ApplicationData.shared.symbolDataList.updateValue(chartDataList, forKey: symbol)
                    } else {
                        ApplicationData.shared.symbolDataList.updateValue(rawSymbolConvertedToMap, forKey: symbol)
                    }
                }
                
                let symbolData = ApplicationData.shared.symbolDataList.first(where: {
                    return $0.key.elementsEqual(symbol)
                })!.value
                
                while(startDate <= Date.now.removeTimeStamp()) {
                    let latestTransaction = newTransactionList.first(where: {
                        return $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
                    })!
                    let oldestSymbolData = symbolData.last(where: {
                        return $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
                    })!
                    chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance * oldestSymbolData.value))
                    startDate.addTimeInterval(86400)
                }
                ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountInBroker.accountInBroker.id!)
                return newTransactionList.last!.timestamp.removeTimeStamp()
            } else {
                if(!ApplicationData.shared.symbolDataList.contains(where: {
                    return $0.key.elementsEqual(symbol)
                })) {
                    let symbolList = await FinanceController().getSymbolDetail(symbol: symbol, range: "10y")
                    
                    let rawSymbolConvertedToMap = ChartController().convertRawDataToMap(symbol: symbolList)
                    
                    if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code) && !ApplicationData.shared.symbolDataList.contains(where: {
                        return $0.key.elementsEqual(symbolList.currency!)
                    })) {
                        let currencyList = await FinanceController().getCurrencyDetail(accountCurrency: SettingsController().getDefaultCurrency().code, range: "10y")
                        let rawCurrencyConvertedToMap = ChartController().convertRawDataToMap(symbol: currencyList)
                        ApplicationData.shared.symbolDataList.updateValue(rawCurrencyConvertedToMap, forKey: symbolList.currency!)
                    }
                    
                    if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code)) {
                        let currencyData = ApplicationData.shared.symbolDataList.first(where: {
                            return $0.key.elementsEqual(symbolList.currency!)
                        })!.value
                        
                        var chartDataList = [ChartData]()
                        for symbol in rawSymbolConvertedToMap {
                            let data = currencyData.last(where: {
                                return $0.date.removeTimeStamp() <= symbol.date.removeTimeStamp()
                            }) ?? nil
                            
                            if(data != nil) {
                                chartDataList.append(ChartData(date: symbol.date.removeTimeStamp(), value: symbol.value * data!.value))
                            }
                        }
                        
                        ApplicationData.shared.symbolDataList.updateValue(chartDataList, forKey: symbol)
                    } else {
                        ApplicationData.shared.symbolDataList.updateValue(rawSymbolConvertedToMap, forKey: symbol)
                    }
                }
                
                let symbolData = ApplicationData.shared.symbolDataList.first(where: {
                    return $0.key.elementsEqual(symbol)
                })!.value
                
                var chartData = ApplicationData.shared.chartDataList.first(where: {
                    return $0.key.elementsEqual(accountInBroker.accountInBroker.id!)
                })!.value
                
                var startDate = chartData.last!.date.addingTimeInterval(86400).removeTimeStamp()
                while(startDate <= Date.now.removeTimeStamp()) {
                    let oldestSymbolData = symbolData.last(where: {
                        return $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
                    })!
                    chartData.append(ChartData(date: startDate, value: transactionList.first!.currentBalance * oldestSymbolData.value))
                    startDate.addTimeInterval(86400)
                }
                ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountInBroker.accountInBroker.id!)
            }
        } else if(accountInBroker.accountTransaction.count == 0){
            let firstData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountInBroker.accountInBroker.id!)
            })?.value.first?.date.removeTimeStamp() ?? Date().removeTimeStamp()
            ApplicationData.shared.chartDataList.removeValue(forKey: accountInBroker.accountInBroker.id!)
            return firstData
        }
        return Date().removeTimeStamp()
    }
    
    public static func loadChartDataForNonExistingBrokerAccount(accountInBroker: AccountInBrokerData) async -> Date {
        if(accountInBroker.accountTransaction.count > 0) {
            let symbol = accountInBroker.accountInBroker.symbol
            if(!ApplicationData.shared.symbolDataList.contains(where: {
                return $0.key.elementsEqual(symbol)
            })) {
                let symbolList = await FinanceController().getSymbolDetail(symbol: symbol, range: "5y")
                
                let rawSymbolConvertedToMap = ChartController().convertRawDataToMap(symbol: symbolList)
                
                if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code) && !ApplicationData.shared.symbolDataList.contains(where: {
                    return $0.key.elementsEqual(symbolList.currency!)
                })) {
                    let currencyList = await FinanceController().getCurrencyDetail(accountCurrency: SettingsController().getDefaultCurrency().code, range: "10y")
                    let rawCurrencyConvertedToMap = ChartController().convertRawDataToMap(symbol: currencyList)
                    ApplicationData.shared.symbolDataList.updateValue(rawCurrencyConvertedToMap, forKey: symbolList.currency!)
                }
                
                if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code)) {
                    let currencyData = ApplicationData.shared.symbolDataList.first(where: {
                        return $0.key.elementsEqual(symbolList.currency!)
                    })!.value
                    
                    var chartDataList = [ChartData]()
                    for symbol in rawSymbolConvertedToMap {
                        let data = currencyData.last(where: {
                            return $0.date.removeTimeStamp() <= symbol.date.removeTimeStamp()
                        })!
                        
                        chartDataList.append(ChartData(date: symbol.date.removeTimeStamp(), value: symbol.value * data.value))
                    }
                    
                    ApplicationData.shared.symbolDataList.updateValue(chartDataList, forKey: symbol)
                } else {
                    ApplicationData.shared.symbolDataList.updateValue(rawSymbolConvertedToMap, forKey: symbol)
                }
            }
            
            let transactionList = accountInBroker.accountTransaction
            let symbolData = ApplicationData.shared.symbolDataList.first(where: {
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
            ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountInBroker.accountInBroker.id!)
            return transactionList.last!.timestamp.removeTimeStamp()
        } else {
            let firstData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountInBroker.accountInBroker.id!)
            })?.value.first?.date.removeTimeStamp() ?? Date().removeTimeStamp()
            ApplicationData.shared.chartDataList.removeValue(forKey: accountInBroker.accountInBroker.id!)
            return firstData
        }
    }
    
    public static func loadChartDataForNonBrokerAccount(accountData: AccountData) async -> Date {
        if(isAccountAvailableInChartDataList(accountID: accountData.account.id!)) {
            return await loadChartDataForExistingNonBrokerAccount(accountData: accountData)
        } else {
            return await loadChartDataForNonExistingNonBrokerAccount(accountData: accountData)
        }
    }
    
    public static func loadChartDataForExistingNonBrokerAccount(accountData: AccountData) async -> Date {
        let transactionList = accountData.accountTransaction
        let index = transactionList.lastIndex(where: {
            return $0.createdDate >= ApplicationData.shared.chartLastUpdated
        })
        if(index != nil) {
            let newTransactionList = transactionList[0...index!]
            
            if(!newTransactionList.isEmpty) {
                var chartData = ApplicationData.shared.chartDataList.first(where: {
                    return $0.key.elementsEqual(accountData.account.id!)
                })!.value
                chartData.removeAll(where: {
                    return $0.date.removeTimeStamp() >= newTransactionList.last!.timestamp
                })
                for i in 0..<newTransactionList.count {
                    if(chartData.contains(where: {
                        return $0.date.removeTimeStamp() == newTransactionList[newTransactionList.count - 1 - i].timestamp.removeTimeStamp()
                    })) {
                        chartData.removeLast()
                    }
                    chartData.append(ChartData(date: newTransactionList[newTransactionList.count - 1 - i].timestamp.removeTimeStamp(), value: newTransactionList[newTransactionList.count - 1 - i].currentBalance))
                }
                ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
                return newTransactionList.last!.timestamp.removeTimeStamp()
            }
        }
        return Date().removeTimeStamp()
    }
    
    public static func loadChartDataForNonExistingNonBrokerAccount(accountData: AccountData) async -> Date {
        let transactionList = accountData.accountTransaction
        var chartData = [ChartData]()
        var chart = [Date: Bool]()
        for i in 0..<transactionList.count {
            if(!chart.contains(where: {
                return $0.key == transactionList[i].timestamp.removeTimeStamp()
            })) {
                chart.updateValue(true, forKey: transactionList[i].timestamp.removeTimeStamp())
                chartData.insert(ChartData(date: transactionList[i].timestamp.removeTimeStamp(), value: transactionList[i].currentBalance), at: 0)
            }
        }
        ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
        return transactionList.last?.timestamp.removeTimeStamp() ?? Date().removeTimeStamp()
    }
    
    public static func generateChartDataForEachAccountType(isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async {
        let accountDataList = ApplicationData.shared.data.accountDataList
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
                    let chartDataListResult = await self.generateChartdataForMixedAccounts(accountType: "Inactive Account", accountDataList: accountDataList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
                    ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: "Inactive Account")
                } else {
                    let chartDataListResult = await self.generateChartDataForMultipleBrokerAccounts(accountType: ConstantUtils.brokerAccountType, accountDataList: accountDataList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
                    ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: ConstantUtils.brokerAccountType)
                }
            } else {
                let chartDataListResult = await self.generateChartDataForMultipleNonBrokerAccount(accountType: accountType, accountDataList: accountDataList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
                ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: accountType)
            }
        }
    }
    
    public static func generateChartDataForEachWatchList(isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async {
        let watchList = await WatchController().getAllWatchList()
        for watch in watchList {
            let chartDataListResult = self.generateChartDataForWatchAccount(id: watch.id!, accountIDList: watch.accountID, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
            ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: watch.id!)
        }
    }
    
    public static func generateChartDataForWatchAccount(id: String, accountIDList: [String], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(id)
            })?.value ?? [ChartData]()
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        var dummy = [[ChartData]]()
        for accountID in accountIDList {
            let chartData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountID)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = Date.now
        if(isRefreshOperation) {
            startDate = refreshChartStartDate
        } else {
            startDate = dummy.min(by: {
                return $0.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date <= $1.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date
            })?.first?.date.removeTimeStamp() ?? startDate.addingTimeInterval(86400).removeTimeStamp()
        }
        
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
    
    public static func generateChartDataForMultipleNonBrokerAccount(accountType: String, accountDataList: [AccountData], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountType)
            })?.value ?? [ChartData]()
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        var dummy = [[ChartData]]()
        for accountData in accountDataList {
            let chartData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountData.account.id!)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = Date.now
        if(isRefreshOperation) {
            startDate = refreshChartStartDate
        } else {
            startDate = dummy.min(by: {
                return $0.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date <= $1.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date
            })!.first!.date.removeTimeStamp()
        }
        
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
    
    public static func generateChartDataForMultipleBrokerAccounts(accountType: String, accountDataList: [AccountData], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountType)
            })?.value ?? [ChartData]()
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        var dummy = [[ChartData]]()
        for accountInBroker in accountDataList {
            let chartData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountInBroker.account.id!)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = Date.now
        if(isRefreshOperation) {
            startDate = refreshChartStartDate
        } else {
            startDate = dummy.min(by: {
                return $0.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date <= $1.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date
            })!.first!.date.removeTimeStamp()
        }
        
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
    
    public static func generateChartdataForMixedAccounts(accountType: String, accountDataList: [AccountData], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountType)
            })?.value ?? [ChartData]()
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        
        var nonBrokerAccountList = [AccountData]()
        var brokerAccountList = [AccountData]()
        
        for accountData in accountDataList {
            if(accountData.account.accountType.elementsEqual(ConstantUtils.brokerAccountType)) {
                brokerAccountList.append(accountData)
            } else {
                nonBrokerAccountList.append(accountData)
            }
        }
        
        let chartDataForNonBrokerAccountList = await generateChartDataForMultipleNonBrokerAccount(accountType: accountType, accountDataList: nonBrokerAccountList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
        let chartDataForBrokerAccountList = await generateChartDataForMultipleBrokerAccounts(accountType: accountType, accountDataList: brokerAccountList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
        
        var startDate = Date.now
        if(isRefreshOperation) {
            startDate = refreshChartStartDate
        } else {
            startDate = getStartDate(chartDataForNonBrokerAccountList: chartDataForNonBrokerAccountList, chartDataForBrokerAccountList: chartDataForBrokerAccountList)
        }
        
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
    
    public static func generateChartDataForOneBrokerAccount(accountData: AccountData, isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountData.account.id!)
            })?.value ?? [ChartData]()
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        var dummy = [[ChartData]]()
        for accountInBroker in accountData.accountInBroker {
            let chartData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountInBroker.accountInBroker.id!)
            })?.value ?? [ChartData]()
            
            dummy.append(chartData)
        }
        
        var startDate = Date.now
        if(isRefreshOperation) {
            startDate = refreshChartStartDate
        } else {
            startDate = dummy.min(by: {
                return $0.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date <= $1.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date
            })?.first!.date.removeTimeStamp() ?? Date().addingTimeInterval(86400).removeTimeStamp()
        }
        
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
    
    public static func getStartDate(chartDataForNonBrokerAccountList: [ChartData], chartDataForBrokerAccountList: [ChartData]) -> Date {
        if(chartDataForBrokerAccountList.count > 0 && chartDataForNonBrokerAccountList.count > 0) {
            return (chartDataForBrokerAccountList.first!.date.removeTimeStamp() >= chartDataForNonBrokerAccountList.first!.date.removeTimeStamp()) ? chartDataForNonBrokerAccountList.first!.date : chartDataForBrokerAccountList.first!.date
        } else if(chartDataForBrokerAccountList.count > 0) {
            return chartDataForBrokerAccountList.first!.date.removeTimeStamp()
        } else if(chartDataForNonBrokerAccountList.count > 0) {
            return chartDataForNonBrokerAccountList.first!.date.removeTimeStamp()
        }
        return Date.now.removeTimeStamp().addingTimeInterval(86400)
    }
    
    public static func isAccountAvailableInChartDataList(accountID: String) -> Bool {
        return ApplicationData.shared.chartDataList.contains(where: {
            return $0.key.elementsEqual(accountID)
        })
    }
}
