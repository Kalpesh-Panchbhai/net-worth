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
    
    public func getChartData(id: String, range: String) async {
        let chartDataList = await chartController.getChartData(id: id, range: range)
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
