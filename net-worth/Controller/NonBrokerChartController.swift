//
//  NonBrokerChartController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/03/24.
//

import Foundation

class NonBrokerChartController {
    
    public func loadChartDataForNonBrokerAccount(accountData: AccountData) async {
        if(CommonChartController().isAccountAvailableInChartDataList(accountID: accountData.account.id!)) {
            return await loadChartDataForExistingNonBrokerAccount(accountData: accountData)
        } else {
            return await loadChartDataForNonExistingNonBrokerAccount(accountData: accountData)
        }
    }
    
    public func loadChartDataForExistingNonBrokerAccount(accountData: AccountData) async {
        if(accountData.account.lastUpdated > ApplicationData.shared.chartLastUpdated) {
            return await loadChartDataForExistingNonBrokerAccountWithLatestCloudData(accountData: accountData)
        } else {
            return await loadChartDataForExistingNonBrokerAccountWithExistingData(accountData: accountData)
        }
    }
    
    public func loadChartDataForExistingNonBrokerAccountWithLatestCloudData(accountData: AccountData) async {
        let transactionList = accountData.accountTransaction
        let newTransactionList = transactionList.filter {
            return $0.createdDate >= ApplicationData.shared.chartLastUpdated
        }
        var chartData = ApplicationData.shared.chartDataList.first(where: {
            return $0.key.elementsEqual(accountData.account.id!)
        })!.value
        chartData.removeAll(where: {
            return $0.date.removeTimeStamp() >= newTransactionList.last!.timestamp
        })
        if(!chartData.isEmpty) {
            chartData.removeLast()
        }
        var startDate = Date.now
        if(chartData.isEmpty) {
            startDate = newTransactionList.last!.timestamp.removeTimeStamp()
        } else {
            startDate = chartData.last!.date.addingTimeInterval(86400).removeTimeStamp()
        }
        
        while(startDate <= Date.now.removeTimeStamp()) {
            let latestTransaction = newTransactionList.first(where: {
                return $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
            })!
            chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance))
            startDate.addTimeInterval(86400)
        }
        ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
    }
    
    public func loadChartDataForExistingNonBrokerAccountWithExistingData(accountData: AccountData) async {
        let latestTransaction = accountData.accountTransaction.first!
        var chartData = ApplicationData.shared.chartDataList.first(where: {
            return $0.key.elementsEqual(accountData.account.id!)
        })!.value
        var startDate = chartData.last!.date.removeTimeStamp().addingTimeInterval(86400)
        while(startDate <= Date.now.removeTimeStamp()) {
            chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance))
            startDate.addTimeInterval(86400)
        }
        ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
    }
    
    public func loadChartDataForNonExistingNonBrokerAccount(accountData: AccountData) async {
        let transactionList = accountData.accountTransaction
        var chartData = [ChartData]()
        var chart = [Date: Bool]()
        for i in 0..<transactionList.count {
            if(!chart.contains(where: {
                return $0.key == transactionList[i].timestamp.removeTimeStamp()
            })) {
                chart.updateValue(true, forKey: transactionList[i].timestamp.removeTimeStamp())
                chartData.insert(ChartData(date: transactionList[i].timestamp.removeTimeStamp(), value: transactionList[i].currentBalance), at: 0)
            }
        }
        ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
    }
    
}
