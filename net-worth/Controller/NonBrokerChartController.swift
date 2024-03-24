//
//  NonBrokerChartController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/03/24.
//

import Foundation

class NonBrokerChartController {
    
    public func loadChartDataForNonBrokerAccount(accountData: AccountData) async -> Date {
        if(CommonChartController().isAccountAvailableInChartDataList(accountID: accountData.account.id!)) {
            return await loadChartDataForExistingNonBrokerAccount(accountData: accountData)
        } else {
            return await loadChartDataForNonExistingNonBrokerAccount(accountData: accountData)
        }
    }
    
    public func loadChartDataForExistingNonBrokerAccount(accountData: AccountData) async -> Date {
        if(accountData.account.lastUpdated > ApplicationData.shared.lastUpdatedChartTimestamp) {
            return await loadChartDataForExistingNonBrokerAccountWithLatestCloudData(accountData: accountData)
        } else {
            return await loadChartDataForExistingNonBrokerAccountWithExistingData(accountData: accountData)
        }
    }
    
    public func loadChartDataForExistingNonBrokerAccountWithLatestCloudData(accountData: AccountData) async -> Date {
        let transactionList = accountData.accountTransaction
        var refreshChartStartDate = Date.now.removeTimeStamp()
        let newTransactionList = transactionList.filter {
            return $0.createdDate >= ApplicationData.shared.lastUpdatedChartTimestamp
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
        refreshChartStartDate = startDate
        
        while(startDate <= Date.now.removeTimeStamp()) {
            let latestTransaction = newTransactionList.first(where: {
                return $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
            })!
            chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance))
            startDate.addTimeInterval(86400)
        }
        ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
        return refreshChartStartDate
    }
    
    public func loadChartDataForExistingNonBrokerAccountWithExistingData(accountData: AccountData) async -> Date {
        let latestTransaction = accountData.accountTransaction.first!
        var refreshChartStartDate = Date.now.removeTimeStamp()
        var chartData = ApplicationData.shared.chartDataList.first(where: {
            return $0.key.elementsEqual(accountData.account.id!)
        })!.value
        var startDate = chartData.last!.date.removeTimeStamp().addingTimeInterval(86400)
        refreshChartStartDate = startDate
        while(startDate <= Date.now.removeTimeStamp()) {
            chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance))
            startDate.addTimeInterval(86400)
        }
        ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
        return refreshChartStartDate
    }
    
    public func loadChartDataForNonExistingNonBrokerAccount(accountData: AccountData) async -> Date {
        let transactionList = accountData.accountTransaction
        var startDate = transactionList.last!.timestamp.removeTimeStamp()
        let refreshChartStartDate = startDate
        var chartData = [ChartData]()
        while(startDate <= Date.now.removeTimeStamp()) {
            let latestTransaction = transactionList.first(where: {
                return $0.timestamp.removeTimeStamp() <= startDate.removeTimeStamp()
            })!
            chartData.append(ChartData(date: startDate, value: latestTransaction.currentBalance))
            startDate.addTimeInterval(86400)
        }
        ApplicationData.shared.chartDataList.updateValue(chartData, forKey: accountData.account.id!)
        return refreshChartStartDate
    }
    
}
