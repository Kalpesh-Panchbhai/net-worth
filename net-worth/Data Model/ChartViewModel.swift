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
//        print(accountViewModel.accountTransactionListWithRange.last ?? <#default value#>)
        
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth, .month, .year]
        dateComponentsFormatter.maximumUnitCount = 1
        dateComponentsFormatter.unitsStyle = .full
        dateComponentsFormatter.string(from: Date(), to: accountViewModel.accountTransactionListWithRange.last?.timestamp ?? Date())  // "1 month"
    }
}
