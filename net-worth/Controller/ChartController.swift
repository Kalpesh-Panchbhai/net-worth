//
//  ChartController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/12/23.
//

import Foundation
import FirebaseFirestore

class ChartController {
    
    public func getChartDataForOneAccountInANonBroker(accountViewModel: AccountViewModel, range: String) async -> [ChartData] {
        var chartDataListResponse = [ChartData]()
        var startDate = Date().removeTimeStamp()
        let accountTransactionListWithRange = accountViewModel.accountTransactionListWithRange
        let accountTransactionListBelowRange = accountViewModel.accountTransactionListBelowRange
        if(range.elementsEqual("All")) {
            if(!accountTransactionListWithRange.isEmpty) {
                startDate = accountTransactionListWithRange.last!.timestamp.removeTimeStamp()
                while(startDate <= Date.now.removeTimeStamp()) {
                    let accountTransaction = accountTransactionListWithRange.first(where: {
                        $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
                    })
                    chartDataListResponse.append(ChartData(date: startDate.removeTimeStamp(), value: accountTransaction!.currentBalance))
                    startDate = CommonController.getIntervalForDateRange(date: startDate, range: range)
                }
            }
        } else {
            startDate = CommonController.getStartDateForRange(range: range)
            while(startDate <= Date.now.removeTimeStamp()) {
                var accountTransaction = accountTransactionListWithRange.first(where: {
                    $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
                })
                if(accountTransaction == nil) {
                    accountTransaction = accountTransactionListBelowRange.first(where: {
                        $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
                    })
                }
                chartDataListResponse.append(ChartData(date: startDate.removeTimeStamp(), value: accountTransaction!.currentBalance))
                startDate = CommonController.getIntervalForDateRange(date: startDate, range: range)
            }
        }
        return chartDataListResponse
    }
    
    public func getChartDataForAllAccountsInANonBroker(accountViewModel: AccountViewModel, range: String) async -> [ChartData] {
        var accountUniqueIndex = 0
        var list = [Int: Double]()
        var chartDataListResponse = [ChartData]()
        var startDate = CommonController.getStartDateForRange(range: range).removeTimeStamp()
        
        let accountTransactionListMultipleNonBrokerAccountsWithRange = accountViewModel.accountTransactionListMultipleNonBrokerAccountsWithRange
        let accountTransactionListMultipleNonBrokerAccountsBelowRange = accountViewModel.accountTransactionListMultipleNonBrokerAccountsBelowRange
        
        while(startDate <= Date.now) {
            accountUniqueIndex = 0
            for account in accountTransactionListMultipleNonBrokerAccountsWithRange {
                let accountTransactionsListBeforeDate = account.filter({ value in
                    value.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
                })
                if(!accountTransactionsListBeforeDate.isEmpty) {
                    list.updateValue(accountTransactionsListBeforeDate[0].currentBalance, forKey: accountUniqueIndex)
                } else {
                    if(!accountTransactionListMultipleNonBrokerAccountsBelowRange[accountUniqueIndex].isEmpty) {
                        list.updateValue(accountTransactionListMultipleNonBrokerAccountsBelowRange[accountUniqueIndex][0].currentBalance, forKey: accountUniqueIndex)
                    }
                }
                accountUniqueIndex+=1
            }
            var totalAmountForEachDate = 0.0
            list.forEach({ key, value in
                totalAmountForEachDate = totalAmountForEachDate + value
            })
            chartDataListResponse.append(ChartData(date: startDate, value: totalAmountForEachDate))
            
            startDate = CommonController.getIntervalForDateRange(date: startDate, range: range)
        }
        
        return chartDataListResponse
    }
    
    public func getChartDataForOneAccountInABroker(accountTransactionListWithRange: [AccountTransaction], accountTransactionListBelowRange: [AccountTransaction], symbol: FinanceDetailModel, currency: FinanceDetailModel, range: String) async -> [ChartData] {
        var chartDataListResponse = [ChartData]()
        
        let symbolMappedDataList = convertRawDataToMap(symbol: symbol)
        let currencyMappedDataList = convertRawDataToMap(symbol: currency)
        
        var startDate = CommonController.getStartDateForRange(range: range)
        var zeroUnits = false
        
        while(startDate <= Date.now.removeTimeStamp()) {
            let symbolMappedData = symbolMappedDataList.last(where: {
                $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
            })
            var filterTransactions = accountTransactionListWithRange.filter({
                $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
            })
            if(filterTransactions.isEmpty) {
                filterTransactions = accountTransactionListBelowRange.filter({
                    $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
                })
            }
            if((!filterTransactions.isEmpty && !zeroUnits) || (!filterTransactions.isEmpty && zeroUnits && filterTransactions[0].currentBalance != 0)) {
                var currencyValue = 1.0
                if(symbol.currency != SettingsController().getDefaultCurrency().code) {
                    let currencyMappedData = currencyMappedDataList.filter({
                        $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
                    })
                    if(!currencyMappedData.isEmpty) {
                        currencyValue = currencyMappedData.last!.value
                    }
                }
                let currentUnits = filterTransactions[0].currentBalance
                if(currentUnits == 0) {
                    zeroUnits = true
                } else {
                    zeroUnits = false
                }
                let currentBalance = currentUnits * (symbolMappedData?.value ?? 1.0) * currencyValue
                let chartData = ChartData(date: startDate.removeTimeStamp(), value: currentBalance)
                chartDataListResponse.append(chartData)
            }
            startDate = CommonController.getIntervalForDateRange(date: startDate, range: range)
        }
        return chartDataListResponse
    }
    
    public func getChartDataForAllAccountsInABroker(accountViewModel: AccountViewModel, financeViewModel: FinanceViewModel, range: String) async -> [ChartData] {
        let accountTransactionListMultipleBrokerAccountsWithRange = accountViewModel.accountTransactionListMultipleBrokerAccountsWithRange
        let accountTransactionListMultipleBrokerAccountsBelowRange = accountViewModel.accountTransactionListMultipleBrokerAccountsBelowRange
        let multipleSymbolList = financeViewModel.multipleSymbolList
        let multipleCurrencyList = financeViewModel.multipleCurrencyList
        
        var multipleAccountsChartData = [ChartData]()
        
        for i in 0..<accountTransactionListMultipleBrokerAccountsWithRange.count {
            let chartDataListResponse = await getChartDataForOneAccountInABroker(accountTransactionListWithRange: accountTransactionListMultipleBrokerAccountsWithRange[i], accountTransactionListBelowRange: accountTransactionListMultipleBrokerAccountsBelowRange[i], symbol: multipleSymbolList[i], currency: multipleCurrencyList[i], range: range)
            
            for chartData in chartDataListResponse {
                if(multipleAccountsChartData.contains(where: {
                    $0.date.removeTimeStamp() == chartData.date.removeTimeStamp()
                })) {
                    multipleAccountsChartData = multipleAccountsChartData.map {
                        var newValue = $0
                        if($0.date.removeTimeStamp() == chartData.date.removeTimeStamp()) {
                            newValue.value = newValue.value + chartData.value
                        }
                        return newValue
                    }
                } else {
                    multipleAccountsChartData.append(chartData)
                }
                multipleAccountsChartData.sort(by: {
                    $0.date < $1.date
                })
            }
        }
        return multipleAccountsChartData
    }
    
    public func getChartDataForAllAccounts(accountViewModel: AccountViewModel, financeViewModel: FinanceViewModel, range: String) async -> [ChartData] {
        let chartDataForNonBrokerAccounts = await getChartDataForAllAccountsInANonBroker(accountViewModel: accountViewModel, range: range)
        let chartDataForBrokerAccounts = await getChartDataForAllAccountsInABroker(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
        var chartDataList = [ChartData]()
        if(!chartDataForNonBrokerAccounts.isEmpty || !chartDataForBrokerAccounts.isEmpty) {
            var startDate = Date()
            if(!chartDataForBrokerAccounts.isEmpty && !chartDataForNonBrokerAccounts.isEmpty) {
                startDate = (chartDataForBrokerAccounts.first!.date.removeTimeStamp() < chartDataForNonBrokerAccounts.first!.date.removeTimeStamp()) ? chartDataForBrokerAccounts.first!.date.removeTimeStamp() : chartDataForNonBrokerAccounts.first!.date.removeTimeStamp()
            } else if(chartDataForBrokerAccounts.isEmpty) {
                startDate = chartDataForNonBrokerAccounts.first!.date.removeTimeStamp()
            } else {
                startDate = chartDataForBrokerAccounts.first!.date.removeTimeStamp()
            }
            
            while(startDate <= Date.now.removeTimeStamp()) {
                let value1 = chartDataForNonBrokerAccounts.last(where: {
                    $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
                })?.value ?? 0.0
                let value2 = chartDataForBrokerAccounts.last(where: {
                    $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
                })?.value ?? 0.0
                let chartData = ChartData(date: startDate, value: (value1 + value2))
                chartDataList.append(chartData)
                startDate = CommonController.getIntervalForDateRange(date: startDate, range: range)
            }
        }
        return chartDataList
    }
    
    private func convertRawDataToMap(symbol: FinanceDetailModel) -> [ChartData] {
        var returnData = [ChartData]()
        let timestampEpochList = symbol.timestamp
        let valueAtTimestampList = symbol.valueAtTimestamp
        
        for i in 0..<timestampEpochList.count {
            let date = convertEpochToDate(epochTime: Double(timestampEpochList[i]!))
            let value = valueAtTimestampList[i] ?? nil
            if(value != nil) {
                returnData.append(ChartData(date: date, value: value!))
            }
        }
        
        return returnData
    }
    
    private func convertEpochToDate(epochTime: Double) -> Date {
        let date = Date(timeIntervalSince1970: TimeInterval(floatLiteral: epochTime))
        return date
    }
}
