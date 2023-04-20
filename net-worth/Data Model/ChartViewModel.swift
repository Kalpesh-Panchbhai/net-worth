//
//  ChartViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 18/02/23.
//

import Foundation

class ChartViewModel: ObservableObject {
    
    @Published var chartDataList = [ChartData]()
    
    func getChartData(account: Account, accountViewModel: AccountViewModel,range: String) async {
        DispatchQueue.main.async {
            var chartDataListResponse = [ChartData]()
            for account in accountViewModel.accountTransactionListWithRange {
                chartDataListResponse.append(ChartData(date: account.timestamp, value: account.balanceChange))
            }
            self.chartDataList = chartDataListResponse
        }
    }
}
