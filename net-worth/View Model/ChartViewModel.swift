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
            for account in accountViewModel.accountTransactionListWithRange {
                if(!chartDataListResponse.contains(where: {
                    $0.date == account.timestamp.removeTimeStamp()
                })) {
                    chartDataListResponse.append(ChartData(date: account.timestamp.removeTimeStamp(), value: account.currentBalance))
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
                startDate = startDate.addingTimeInterval(-86400)
                for account in accountViewModel.accountTransactionLastTransactionBelowRange {
                    list.updateValue(account.first?.currentBalance ?? 0.0, forKey: accountUniqueIndex)
                    accountUniqueIndex+=1
                }
                var totalAmountForEachDate = 0.0
                list.forEach({ key, value in
                    totalAmountForEachDate = totalAmountForEachDate + value
                })
                chartDataListResponse.append(ChartData(date: startDate, value: totalAmountForEachDate))
                startDate = startDate.addingTimeInterval(86400)
            }
            while(startDate <= Date.now) {
                accountUniqueIndex = 0
                for account in accountViewModel.accountTransactionListWithRangeMultipleAccounts {
                    if(account.contains(where: { value in
                        value.timestamp.removeTimeStamp() == startDate.removeTimeStamp()
                    })) {
                        list.updateValue(account.filter({ value in
                            value.timestamp.removeTimeStamp() == startDate.removeTimeStamp()
                        }).first!.currentBalance, forKey: accountUniqueIndex)
                    }
                    accountUniqueIndex+=1
                }
                var totalAmountForEachDate = 0.0
                list.forEach({ key, value in
                    totalAmountForEachDate = totalAmountForEachDate + value
                })
                chartDataListResponse.append(ChartData(date: startDate, value: totalAmountForEachDate))
                startDate = startDate.addingTimeInterval(86400)
            }
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
                if(incomeViewModel.incomeList.contains {
                    $0.creditedOn.removeTimeStamp() == chartData.date.removeTimeStamp()
                }) {
                    currentTotalIncome = incomeViewModel.incomeList.filter {
                        $0.creditedOn.removeTimeStamp() == chartData.date.removeTimeStamp()
                    }.first!.cumulativeAmount
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
