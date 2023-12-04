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
    
    func getChartDataForAccounts(accountViewModel: AccountViewModel, range: String) async {
        DispatchQueue.main.async {
            var accountUniqueIndex = 0
            var chartDataListResponse = [ChartData]()
            var list = [Int: Double]()
            var startDate = Date.now
            for account in accountViewModel.accountTransactionListWithRangeMultipleAccounts {
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
                for account in accountViewModel.accountTransactionLastTransactionBelowRange {
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
                for account in accountViewModel.accountTransactionListWithRangeMultipleAccounts {
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
            for account in accountViewModel.accountTransactionListWithRangeMultipleAccounts {
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
            self.chartDataList = chartDataListResponse
        }
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
    
    func getBrokerChartData(accountViewModel: AccountViewModel, financeViewModel: FinanceViewModel) async {
        DispatchQueue.main.async {
            var chartDataListResponse = [ChartData]()
            let accountTransactionListWithRange = accountViewModel.accountTransactionListWithRange
            let accountTransactionListBelowRange = accountViewModel.accountTransactionListBelowRange
            
            let symbolMappedDataList = self.convertRawDataToMap(symbol: financeViewModel.symbol)
            let currencyMappedDataList = self.convertRawDataToMap(symbol: financeViewModel.currency)
            
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
                    if(financeViewModel.symbol.currency != SettingsController().getDefaultCurrency().code) {
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
            self.chartDataList = chartDataListResponse
        }
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
}
