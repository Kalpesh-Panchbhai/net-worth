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
