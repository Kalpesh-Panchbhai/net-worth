//
//  BrokerChartController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 08/03/24.
//

import Foundation

class BrokerChartController {
    
    var chartController = ChartController()
    
    public func loadChartDataForBrokerAccount(accountData: AccountData) async -> Date {
        let accountInBrokerList = accountData.accountInBroker
        var refreshChartStartDate = Date.now.removeTimeStamp()
        for accountInBroker in accountInBrokerList {
            if(ApplicationData.shared.chartDataList.contains(where: {
                return $0.key.elementsEqual(accountInBroker.accountInBroker.id!)
            })) {
                let chartStartDate = await loadChartDataForExistingBrokerAccount(accountInBroker: accountInBroker)
                if(chartStartDate <= refreshChartStartDate) {
                    refreshChartStartDate = chartStartDate
                }
            } else {
                let chartStartDate = await loadChartDataForNonExistingBrokerAccount(accountInBroker: accountInBroker)
                if(chartStartDate <= refreshChartStartDate) {
                    refreshChartStartDate = chartStartDate
                }
            }
        }
        if(CommonChartController().isAccountAvailableInChartDataList(accountID: accountData.account.id!)) {
            let chartDataList = CommonChartController().generateChartDataForOneBrokerAccount(accountData: accountData, isRefreshOperation: true, refreshChartStartDate: refreshChartStartDate)
            ApplicationData.shared.chartDataList.updateValue(chartDataList, forKey: accountData.account.id!)
        } else {
            let chartDataList = CommonChartController().generateChartDataForOneBrokerAccount(accountData: accountData)
            ApplicationData.shared.chartDataList.updateValue(chartDataList, forKey: accountData.account.id!)
        }
        return refreshChartStartDate
    }
    
    public func loadChartDataForExistingBrokerAccount(accountInBroker: AccountInBrokerData) async -> Date {
        if(accountInBroker.accountInBroker.lastUpdated > ApplicationData.shared.lastUpdatedChartTimestamp) {
            return await loadChartDataForExistingBrokerAccountWithLatestCloudData(accountInBroker: accountInBroker)
        } else {
            return await loadChartDataForExistingBrokerAccountWithExistingData(accountInBroker: accountInBroker)
        }
    }
    
    public func loadChartDataForExistingBrokerAccountWithLatestCloudData(accountInBroker: AccountInBrokerData) async -> Date {
        var refreshChartStartDate = Date.now.removeTimeStamp()
        if(accountInBroker.accountTransaction.count > 0) {
            let symbol = accountInBroker.accountInBroker.symbol
            let transactionList = accountInBroker.accountTransaction
            let newTransactionList = transactionList.filter {
                return $0.createdDate >= ApplicationData.shared.lastUpdatedChartTimestamp
            }
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
            refreshChartStartDate = startDate
            
            if(!ApplicationData.shared.symbolDataList.contains(where: {
                return $0.key.elementsEqual(symbol)
            })) {
                let symbolList = await FinanceController().getSymbolDetail(symbol: symbol, range: "10y")
                
                let rawSymbolConvertedToMap = chartController.convertRawDataToMap(symbol: symbolList)
                
                if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code) && !ApplicationData.shared.symbolDataList.contains(where: {
                    return $0.key.elementsEqual(symbolList.currency!)
                })) {
                    let currencyList = await FinanceController().getCurrencyDetail(accountCurrency: SettingsController().getDefaultCurrency().code, range: "10y")
                    let rawCurrencyConvertedToMap = chartController.convertRawDataToMap(symbol: currencyList)
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
        } else {
            ApplicationData.shared.chartDataList.removeValue(forKey: accountInBroker.accountInBroker.id!)
        }
        
        return refreshChartStartDate
    }
    
    public func loadChartDataForExistingBrokerAccountWithExistingData(accountInBroker: AccountInBrokerData) async -> Date {
        var refreshChartStartDate = Date.now.removeTimeStamp()
        if(accountInBroker.accountTransaction.count > 0) {
            let symbol = accountInBroker.accountInBroker.symbol
            let latestTransaction = accountInBroker.accountTransaction.first!
            var chartData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountInBroker.accountInBroker.id!)
            })!.value
            var startDate = chartData.last!.date.removeTimeStamp().addingTimeInterval(86400)
            refreshChartStartDate = startDate
            
            if(!ApplicationData.shared.symbolDataList.contains(where: {
                return $0.key.elementsEqual(symbol)
            })) {
                let symbolList = await FinanceController().getSymbolDetail(symbol: symbol, range: "5y")
                
                let rawSymbolConvertedToMap = chartController.convertRawDataToMap(symbol: symbolList)
                
                if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code) && !ApplicationData.shared.symbolDataList.contains(where: {
                    return $0.key.elementsEqual(symbolList.currency!)
                })) {
                    let currencyList = await FinanceController().getCurrencyDetail(accountCurrency: SettingsController().getDefaultCurrency().code, range: "10y")
                    let rawCurrencyConvertedToMap = chartController.convertRawDataToMap(symbol: currencyList)
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
                let oldestSymbolData = symbolData.last(where: {
                    return $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
                })!
                chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance * oldestSymbolData.value))
                startDate.addTimeInterval(86400)
            }
            ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountInBroker.accountInBroker.id!)
        } else {
            ApplicationData.shared.chartDataList.removeValue(forKey: accountInBroker.accountInBroker.id!)
        }
        
        return refreshChartStartDate
    }
    
    public func loadChartDataForNonExistingBrokerAccount(accountInBroker: AccountInBrokerData) async -> Date {
        var refreshChartStartDate = Date.now.removeTimeStamp()
        if(accountInBroker.accountTransaction.count > 0) {
            let symbol = accountInBroker.accountInBroker.symbol
            if(!ApplicationData.shared.symbolDataList.contains(where: {
                return $0.key.elementsEqual(symbol)
            })) {
                let symbolList = await FinanceController().getSymbolDetail(symbol: symbol, range: "5y")
                
                let rawSymbolConvertedToMap = chartController.convertRawDataToMap(symbol: symbolList)
                
                if(!symbolList.currency!.elementsEqual(SettingsController().getDefaultCurrency().code) && !ApplicationData.shared.symbolDataList.contains(where: {
                    return $0.key.elementsEqual(symbolList.currency!)
                })) {
                    let currencyList = await FinanceController().getCurrencyDetail(accountCurrency: SettingsController().getDefaultCurrency().code, range: "10y")
                    let rawCurrencyConvertedToMap = chartController.convertRawDataToMap(symbol: currencyList)
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
            refreshChartStartDate = startDate
            
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
        } else {
            ApplicationData.shared.chartDataList.removeValue(forKey: accountInBroker.accountInBroker.id!)
        }
        return refreshChartStartDate
    }
}

class NonBrokerChartController {
    
    public func loadChartDataForNonBrokerAccount(accountData: AccountData) async -> Date {
        if(CommonChartController().isAccountAvailableInChartDataList(accountID: accountData.account.id!)) {
            return await loadChartDataForExistingNonBrokerAccount(accountData: accountData)
        } else {
            return await loadChartDataForNonExistingNonBrokerAccount(accountData: accountData)
        }
    }
    
    public func loadChartDataForExistingNonBrokerAccount(accountData: AccountData) async -> Date {
        if(accountData.account.lastUpdated > ApplicationData.shared.lastUpdatedChartTimestamp) {
            return await loadChartDataForExistingNonBrokerAccountWithLatestCloudData(accountData: accountData)
        } else {
            return await loadChartDataForExistingNonBrokerAccountWithExistingData(accountData: accountData)
        }
    }
    
    public func loadChartDataForExistingNonBrokerAccountWithLatestCloudData(accountData: AccountData) async -> Date {
        let transactionList = accountData.accountTransaction
        var refreshChartStartDate = Date.now.removeTimeStamp()
        let newTransactionList = transactionList.filter {
            return $0.createdDate >= ApplicationData.shared.lastUpdatedChartTimestamp
        }
        var chartData = ApplicationData.shared.chartDataList.first(where: {
            return $0.key.elementsEqual(accountData.account.id!)
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
        refreshChartStartDate = startDate
        
        while(startDate <= Date.now.removeTimeStamp()) {
            let latestTransaction = newTransactionList.first(where: {
                return $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
            })!
            chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance))
            startDate.addTimeInterval(86400)
        }
        ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
        return refreshChartStartDate
    }
    
    public func loadChartDataForExistingNonBrokerAccountWithExistingData(accountData: AccountData) async -> Date {
        let latestTransaction = accountData.accountTransaction.first!
        var refreshChartStartDate = Date.now.removeTimeStamp()
        var chartData = ApplicationData.shared.chartDataList.first(where: {
            return $0.key.elementsEqual(accountData.account.id!)
        })!.value
        var startDate = chartData.last!.date.removeTimeStamp().addingTimeInterval(86400)
        refreshChartStartDate = startDate
        while(startDate <= Date.now.removeTimeStamp()) {
            chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance))
            startDate.addTimeInterval(86400)
        }
        ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
        return refreshChartStartDate
    }
    
    public func loadChartDataForNonExistingNonBrokerAccount(accountData: AccountData) async -> Date {
        let transactionList = accountData.accountTransaction
        var startDate = transactionList.last!.timestamp.removeTimeStamp()
        let refreshChartStartDate = startDate
        var chartData = [ChartData]()
        while(startDate <= Date.now.removeTimeStamp()) {
            let latestTransaction = transactionList.first(where: {
                return $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
            })!
            chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance))
            startDate.addTimeInterval(86400)
        }
        ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
        return refreshChartStartDate
    }
    
}

class CommonChartController {
    
    public func generateChartDataForEachAccountType(isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async {
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
                    let chartDataListResult = await generateChartdataForMixedAccounts(accountType: "Inactive Account", accountDataList: accountDataList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
                    ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: "Inactive Account")
                } else {
                    let chartDataListResult = await generateChartDataForMultipleBrokerAccounts(accountType: ConstantUtils.brokerAccountType, accountDataList: accountDataList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
                    ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: ConstantUtils.brokerAccountType)
                }
            } else {
                let chartDataListResult = await generateChartDataForMultipleNonBrokerAccount(accountType: accountType, accountDataList: accountDataList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
                ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: accountType)
            }
        }
    }
    
    public func generateChartDataForEachWatchList(isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async {
        let watchList = await WatchController().getAllWatchList()
        for watch in watchList {
            let chartDataListResult = generateChartDataForWatchAccount(id: watch.id!, accountIDList: watch.accountID, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
            ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: watch.id!)
        }
    }
    
    public func generateChartDataForWatchAccount(id: String, accountIDList: [String], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(id)
            })!.value
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
    
    public func generateChartDataForMultipleNonBrokerAccount(accountType: String, accountDataList: [AccountData], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountType)
            })!.value
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
    
    public func generateChartDataForMultipleBrokerAccounts(accountType: String, accountDataList: [AccountData], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountType)
            })!.value
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
    
    public func generateChartdataForMixedAccounts(accountType: String, accountDataList: [AccountData], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountType)
            })!.value
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
    
    public func generateChartDataForOneBrokerAccount(accountData: AccountData, isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountData.account.id!)
            })!.value
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        var dummy = [[ChartData]]()
        for accountInBroker in accountData.accountInBroker {
            let chartData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountInBroker.accountInBroker.id!)
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
    
    public func getStartDate(chartDataForNonBrokerAccountList: [ChartData], chartDataForBrokerAccountList: [ChartData]) -> Date {
        if(chartDataForBrokerAccountList.count > 0 && chartDataForNonBrokerAccountList.count > 0) {
            return (chartDataForBrokerAccountList.first!.date.removeTimeStamp() >= chartDataForNonBrokerAccountList.first!.date.removeTimeStamp()) ? chartDataForNonBrokerAccountList.first!.date : chartDataForBrokerAccountList.first!.date
        } else if(chartDataForBrokerAccountList.count > 0) {
            return chartDataForBrokerAccountList.first!.date.removeTimeStamp()
        } else if(chartDataForNonBrokerAccountList.count > 0) {
            return chartDataForNonBrokerAccountList.first!.date.removeTimeStamp()
        }
        return Date.now.removeTimeStamp().addingTimeInterval(86400)
    }
    
    public func isAccountAvailableInChartDataList(accountID: String) -> Bool {
        return ApplicationData.shared.chartDataList.contains(where: {
            return $0.key.elementsEqual(accountID)
        })
    }
    
}
