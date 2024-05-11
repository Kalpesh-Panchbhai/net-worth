//
//  ChartController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/12/23.
//

import Foundation

class ChartController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.CHART.rawValue
    
    public func getChartData(id: String, range: String) async -> [ChartData] {
        // TODO: Disabled Chart due to performance issue
//        let chartRestListResponse =  await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: id, forClass: [ChartRest].self)
        let chartRestListResponse = [ChartRest]()
        var chartDataListResponse = [ChartData]()
        
        var chartDataList = chartRestListResponse.map {
            return ChartData(date: $0.date.convertStringToDateForChartData(), value: $0.value)
        }
        chartDataList.sort(by: {
            return $0.date < $1.date
        })
        var startDate = Date().removeTimeStamp()
        var lastDate = Date().removeTimeStamp()
        lastDate = CommonController.getStartDateForRange(range: range)
        
        let count = chartDataList.filter {
            return $0.date >= lastDate
        }.count
        if(!chartDataList.isEmpty) {
            if(count == 0) {
                let daysDifference = startDate.days(from: lastDate)
                let lastTransaction = chartDataList.last!
                while(lastDate <= startDate) {
                    chartDataListResponse.append(ChartData(date: startDate.removeTimeStamp(), value: lastTransaction.value))
                    startDate = getNextStartDate(startDate: startDate, count: Double(daysDifference))
                }
            } else {
                lastDate = chartDataList.filter {
                    return $0.date >= lastDate
                }.first!.date.removeTimeStamp()
                let daysDifference = startDate.days(from: lastDate)
                while(lastDate <= startDate) {
                    let chartData = chartDataList.last {
                        return startDate >= $0.date.removeTimeStamp()
                    }
                    if(chartData != nil) {
                        chartDataListResponse.append(ChartData(date: startDate.removeTimeStamp(), value: chartData!.value))
                    }
                    if(daysDifference == 0) {
                        break;
                    }
                    startDate = getNextStartDate(startDate: startDate, count: Double(daysDifference))
                    
                }
            }
        }
        return chartDataListResponse.reversed()
    }
    
    private func getNextStartDate(startDate: Date, count: Double) -> Date {
        let daysInternal = count / 100.0
        return startDate.addingTimeInterval(-86400 * daysInternal).removeTimeStamp()
    }
    
    public func convertRawDataToMap(symbol: FinanceDetailModel) -> [ChartData] {
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
