//
//  ChartController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/12/23.
//

import Foundation
import FirebaseFirestore

class ChartController {
    
    public func getChartData(id: String, range: String) async -> [ChartData] {
        let chartDataList = ApplicationData.shared.chartDataListByEachType.first(where: {
            return $0.key.elementsEqual(id)
        })!.value
        var chartDataListResponse = [ChartData]()
        var startDate = Date().removeTimeStamp()
        startDate = CommonController.getStartDateForRange(range: range)
        
        while(startDate <= Date.now.removeTimeStamp()) {
            let chartData = chartDataList.last {
                return $0.date.removeTimeStamp() <= startDate
            }
            if(chartData != nil) {
                chartDataListResponse.append(ChartData(date: startDate.removeTimeStamp(), value: chartData!.value))
            }
            startDate = CommonController.getIntervalForDateRange(date: startDate, range: range)
        }
        return chartDataListResponse
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
