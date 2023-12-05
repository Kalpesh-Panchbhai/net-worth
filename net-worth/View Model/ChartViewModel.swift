//
//  ChartViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 18/02/23.
//

import Foundation
import FirebaseFirestore

class ChartViewModel: ObservableObject {
    
    @Published var chartDataList = [ChartData]()
    
    func getChartData(accountViewModel: AccountViewModel) async {
        DispatchQueue.main.async {
            var chartDataListResponse = [ChartData]()
            for transaction in accountViewModel.accountTransactionListWithRange {
                if(!chartDataListResponse.contains(where: {
                    $0.date == transaction.timestamp.removeTimeStamp()
                })) {
                    chartDataListResponse.append(ChartData(date: transaction.timestamp.removeTimeStamp(), value: transaction.currentBalance))
                }
            }
            chartDataListResponse.sort(by: {
                $0.date < $1.date
            })
            self.chartDataList = chartDataListResponse
        }
    }
    
    func getChartDataForNonBrokerAccounts(accountViewModel: AccountViewModel, range: String) async {
        self.chartDataList = await getChartDataForNonBrokerAccountsMainLogic(accountViewModel: accountViewModel, range: range)
    }
    
    private func getChartDataForNonBrokerAccountsMainLogic(accountViewModel: AccountViewModel, range: String) async -> [ChartData] {
        var accountUniqueIndex = 0
        var chartDataListResponse = [ChartData]()
        var list = [Int: Double]()
        var startDate = Date.now
        for account in accountViewModel.accountTransactionListMultipleNonBrokerAccountsWithRange {
            if(!account.isEmpty && startDate > account.last!.timestamp) {
                startDate = account.last!.timestamp
            }
        }
        startDate = startDate.removeTimeStamp()
        if(!range.elementsEqual("All")) {
            var date = Timestamp()
            if(range.elementsEqual("1M")) {
                date = Timestamp.init(date: Date.now.addingTimeInterval(-2592000-86400))
            } else if(range.elementsEqual("3M")) {
                date = Timestamp.init(date: Date.now.addingTimeInterval(-7776000-86400))
            } else if(range.elementsEqual("6M")) {
                date = Timestamp.init(date: Date.now.addingTimeInterval(-15552000-86400))
            } else if(range.elementsEqual("1Y")) {
                date = Timestamp.init(date: Date.now.addingTimeInterval(-31104000-86400))
            } else if(range.elementsEqual("2Y")) {
                date = Timestamp.init(date: Date.now.addingTimeInterval(-62208000-86400))
            } else if(range.elementsEqual("5Y")) {
                date = Timestamp.init(date: Date.now.addingTimeInterval(-155520000-86400))
            }
            for account in accountViewModel.accountTransactionListMultipleNonBrokerAccountsBelowRange {
                list.updateValue(account.first?.currentBalance ?? 0.0, forKey: accountUniqueIndex)
                accountUniqueIndex+=1
            }
            var totalAmountForEachDate = 0.0
            list.forEach({ key, value in
                totalAmountForEachDate = totalAmountForEachDate + value
            })
            chartDataListResponse.append(ChartData(date: date.dateValue().removeTimeStamp(), value: totalAmountForEachDate))
        }
        while(startDate <= Date.now) {
            accountUniqueIndex = 0
            for account in accountViewModel.accountTransactionListMultipleNonBrokerAccountsWithRange {
                let accountTransactionsListBeforeDate = account.filter({ value in
                    value.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
                })
                if(!accountTransactionsListBeforeDate.isEmpty) {
                    list.updateValue(accountTransactionsListBeforeDate[0].currentBalance, forKey: accountUniqueIndex)
                }
                accountUniqueIndex+=1
            }
            var totalAmountForEachDate = 0.0
            list.forEach({ key, value in
                totalAmountForEachDate = totalAmountForEachDate + value
            })
            chartDataListResponse.append(ChartData(date: startDate, value: totalAmountForEachDate))
            
            if(range.elementsEqual("1M")) {
                startDate = Timestamp.init(date: startDate.addingTimeInterval(86400)).dateValue()
            } else if(range.elementsEqual("3M")) {
                startDate = Timestamp.init(date: startDate.addingTimeInterval(86400 * 2)).dateValue()
            } else if(range.elementsEqual("6M")) {
                startDate = Timestamp.init(date: startDate.addingTimeInterval(86400 * 3)).dateValue()
            } else if(range.elementsEqual("1Y")) {
                startDate = Timestamp.init(date: startDate.addingTimeInterval(86400 * 4)).dateValue()
            } else if(range.elementsEqual("2Y")) {
                startDate = Timestamp.init(date: startDate.addingTimeInterval(86400 * 5)).dateValue()
            } else if(range.elementsEqual("5Y")) {
                startDate = Timestamp.init(date: startDate.addingTimeInterval(86400 * 6)).dateValue()
            } else if(range.elementsEqual("All")) {
                startDate = Timestamp.init(date: startDate.addingTimeInterval(86400 * 7)).dateValue()
            }
        }
        startDate = Date.now.removeTimeStamp()
        accountUniqueIndex = 0
        for account in accountViewModel.accountTransactionListMultipleNonBrokerAccountsWithRange {
            let accountTransactionsListBeforeDate = account.filter({ value in
                value.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
            })
            if(!accountTransactionsListBeforeDate.isEmpty) {
                list.updateValue(accountTransactionsListBeforeDate[0].currentBalance, forKey: accountUniqueIndex)
            }
            accountUniqueIndex+=1
        }
        var totalAmountForEachDate = 0.0
        list.forEach({ key, value in
            totalAmountForEachDate = totalAmountForEachDate + value
        })
        chartDataListResponse.append(ChartData(date: startDate, value: totalAmountForEachDate))
        chartDataListResponse.sort(by: {
            $0.date < $1.date
        })
        return chartDataListResponse
    }
    
    func getBrokerChartData(accountViewModel: AccountViewModel, financeViewModel: FinanceViewModel) async {
        let accountTransactionListWithRange = accountViewModel.accountTransactionListWithRange
        let accountTransactionListBelowRange = accountViewModel.accountTransactionListBelowRange
        
        let chartDataListResponse = await self.getBrokerChartData(accountTransactionListWithRange: accountTransactionListWithRange, accountTransactionListBelowRange: accountTransactionListBelowRange, symbol: financeViewModel.symbol, currency: financeViewModel.currency)
        self.chartDataList = chartDataListResponse
    }
    
    private func getBrokerChartData(accountTransactionListWithRange: [AccountTransaction], accountTransactionListBelowRange: [AccountTransaction], symbol: FinanceDetailModel, currency: FinanceDetailModel) async -> [ChartData] {
        var chartDataListResponse = [ChartData]()
        
        let symbolMappedDataList = self.convertRawDataToMap(symbol: symbol)
        let currencyMappedDataList = self.convertRawDataToMap(symbol: currency)
        
        var zeroUnits = false
        for symbolMappedData in symbolMappedDataList {
            var filterTransactions = accountTransactionListWithRange.filter({
                $0.timestamp.removeTimeStamp() <= symbolMappedData.date.removeTimeStamp()
            })
            if(filterTransactions.isEmpty) {
                filterTransactions = accountTransactionListBelowRange.filter({
                    $0.timestamp.removeTimeStamp() <= symbolMappedData.date.removeTimeStamp()
                })
            }
            if((!filterTransactions.isEmpty && !zeroUnits) || (!filterTransactions.isEmpty && zeroUnits && filterTransactions[0].currentBalance != 0)) {
                var currencyValue = 1.0
                if(symbol.currency != SettingsController().getDefaultCurrency().code) {
                    let currencyMappedData = currencyMappedDataList.filter({
                        $0.date.removeTimeStamp() <= symbolMappedData.date.removeTimeStamp()
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
                let currentBalance = currentUnits * symbolMappedData.value * currencyValue
                let chartData = ChartData(date: symbolMappedData.date.removeTimeStamp(), value: currentBalance)
                chartDataListResponse.append(chartData)
            }
        }
        return chartDataListResponse
    }
    
    func getChartDataForBrokerAccounts(accountViewModel: AccountViewModel, financeViewModel: FinanceViewModel) async {
        self.chartDataList = await getChartDataForBrokerAccountsMainLogic(accountViewModel: accountViewModel, financeViewModel: financeViewModel)
    }
    
    private func getChartDataForBrokerAccountsMainLogic(accountViewModel: AccountViewModel, financeViewModel: FinanceViewModel) async -> [ChartData] {
        let accountTransactionListMultipleBrokerAccountsWithRange = accountViewModel.accountTransactionListMultipleBrokerAccountsWithRange
        let accountTransactionListMultipleBrokerAccountsBelowRange = accountViewModel.accountTransactionListMultipleBrokerAccountsBelowRange
        let multipleSymbolList = financeViewModel.multipleSymbolList
        let multipleCurrencyList = financeViewModel.multipleCurrencyList
        
        var multipleAccountsChartData = [ChartData]()
        
        for i in 0..<accountTransactionListMultipleBrokerAccountsWithRange.count {
            let chartDataListResponse = await self.getBrokerChartData(accountTransactionListWithRange: accountTransactionListMultipleBrokerAccountsWithRange[i], accountTransactionListBelowRange: accountTransactionListMultipleBrokerAccountsBelowRange[i], symbol: multipleSymbolList[i], currency: multipleCurrencyList[i])
            
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
    
    func convertEpochToDate(epochTime: Double) -> Date {
        let date = Date(timeIntervalSince1970: TimeInterval(floatLiteral: epochTime))
        return date
    }
    
    func getChartDataForAllAccounts(accountViewModel: AccountViewModel, financeViewModel: FinanceViewModel, range: String) async {
        let chartDataForNonBrokerAccounts = await getChartDataForNonBrokerAccountsMainLogic(accountViewModel: accountViewModel, range: range)
        let chartDataForBrokerAccounts = await getChartDataForBrokerAccountsMainLogic(accountViewModel: accountViewModel, financeViewModel: financeViewModel)
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
                startDate = startDate.addingTimeInterval(86400)
            }
        }
        self.chartDataList = chartDataList
    }
    func getChartDataForNetworth(incomeViewModel: IncomeViewModel) async {
        DispatchQueue.main.async {
            var currentTotalIncome = 0.0
            var chartDataListResponse = [ChartData]()
            for chartData in self.chartDataList {
                let incomeList = incomeViewModel.incomeList.filter {
                    $0.creditedOn <= chartData.date.removeTimeStamp()
                }
                if(!incomeList.isEmpty) {
                    currentTotalIncome = incomeList[0].cumulativeAmount;
                }
                if(currentTotalIncome.isZero) {
                    chartDataListResponse.append(ChartData(date: chartData.date, value: 0))
                } else {
                    chartDataListResponse.append(ChartData(date: chartData.date, value: (chartData.value / currentTotalIncome) * 100))
                }
            }
            chartDataListResponse.sort(by: {
                $0.date < $1.date
            })
            self.chartDataList = chartDataListResponse
        }
    }
}
