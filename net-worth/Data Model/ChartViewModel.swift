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
    
    func getChartData(account: Account, accountViewModel: AccountViewModel, range: String) async {
        DispatchQueue.main.async {
            var chartDataListResponse = [ChartData]()
            for account in accountViewModel.accountTransactionListWithRange {
                chartDataListResponse.append(ChartData(date: account.timestamp, value: account.balanceChange))
            }
            self.chartDataList = chartDataListResponse
        }
    }
    
    func getChartDataForAccounts(accountViewModel: AccountViewModel, range: String) async {
        DispatchQueue.main.async {
            var chartDataListResponse = [ChartData]()
            var list = [String: Double]()
            var startDate = Date.now
            for account in accountViewModel.accountTransactionListWithRangeMultipleAccounts {
                if(!account.isEmpty && startDate > account.last!.timestamp) {
                    startDate = account.last!.timestamp
                }
            }
            startDate = startDate.removeTimeStamp()
            while(startDate <= Date.now) {
                for account in accountViewModel.accountTransactionListWithRangeMultipleAccounts {
                    if(account.contains(where: { value in
                        value.timestamp.getDateAndFormat().elementsEqual(startDate.getDateAndFormat())
                    })) {
                        list.updateValue(account.filter({ value in
                            value.timestamp.getDateAndFormat().elementsEqual(startDate.getDateAndFormat())
                        }).first!.balanceChange, forKey: (account.first?.id)!)
                    }
                }
                var totalAmountForEachDate = 0.0
                list.forEach({ key, value in
                    totalAmountForEachDate = totalAmountForEachDate + value
                })
                chartDataListResponse.append(ChartData(date: startDate, value: totalAmountForEachDate))
                startDate = startDate.addingTimeInterval(86400)
            }
            self.chartDataList = chartDataListResponse
        }
    }
}
