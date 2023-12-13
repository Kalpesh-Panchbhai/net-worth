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
    
    private var chartController = ChartController()
    
    public func getChartDataForOneAccountInANonBroker(accountViewModel: AccountViewModel, range: String) async {
        let chartDataList = await chartController.getChartDataForOneAccountInANonBroker(accountViewModel: accountViewModel, range: range)
        DispatchQueue.main.async {
            self.chartDataList = chartDataList
        }
    }
    
    public func getChartDataForOneAccountInABroker(accountViewModel: AccountViewModel, financeViewModel: FinanceViewModel, range: String) async {
        let accountTransactionListWithRange = accountViewModel.accountTransactionListWithRange
        let accountTransactionListBelowRange = accountViewModel.accountTransactionListBelowRange
        
        let chartDataListResponse = await chartController.getChartDataForOneAccountInABroker(accountTransactionListWithRange: accountTransactionListWithRange, accountTransactionListBelowRange: accountTransactionListBelowRange, symbol: financeViewModel.symbol, currency: financeViewModel.currency, range: range)
        DispatchQueue.main.async {
            self.chartDataList = chartDataListResponse
        }
    }
    
    public func getChartDataForAllAccountsInABroker(accountViewModel: AccountViewModel, financeViewModel: FinanceViewModel, range: String) async {
        let chartDataList = await chartController.getChartDataForAllAccountsInABroker(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
        DispatchQueue.main.async {
            self.chartDataList = chartDataList
        }
    }
    
    public func getChartDataForAllAccounts(accountViewModel: AccountViewModel, financeViewModel: FinanceViewModel, range: String) async {
        let chartDataList = await chartController.getChartDataForAllAccounts(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
        DispatchQueue.main.async {
            self.chartDataList = chartDataList
        }
    }
    
    public func getChartDataForNetworth(incomeViewModel: IncomeViewModel) async {
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
