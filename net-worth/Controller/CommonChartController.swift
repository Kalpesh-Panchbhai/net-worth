//
//  CommonChartController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/03/24.
//

import Foundation

class CommonChartController: ObservableObject {
    
    @Published public var count = 0
    
    public func fetchChartData(fetchLatest: Bool) async {
        if let chartData = UserDefaults.standard.data(forKey: "chartData") {
            do {
                let decoder = JSONDecoder()
                
                ApplicationData.shared.chartDataList = try decoder.decode([String: [ChartData]].self, from: chartData)
            } catch {
                print("Unable to Decode Note (\(error))")
            }
        }
        
        if(fetchLatest) {
            await fetchChartData()
        }
    }
    
    private func fetchChartData() async {
        ApplicationData.shared.chartDataList = [String: [ChartData]]()
        DispatchQueue.main.async {
            self.count = 0
        }
        let _ = await loadChartData()
        await generateChartDataForEachAccountType()
        await generateChartDataForEachWatchList()
        
        updateChartData()
    }
    
    public func getChartLastUpdatedDate() {
        let date = UserDefaults.standard.string(forKey: "chartLastUpdated") ?? "\(Date.now.getEarliestDate())"
        ApplicationData.shared.lastUpdatedChartTimestamp = date.toFullDateFormat()
    }
    
    public func removeChartDataListUptoLastUpdatedDate() {
        ApplicationData.shared.chartDataList = ApplicationData.shared.chartDataList.mapValues {
            return $0.filter {
                return $0.date.removeTimeStamp() < ApplicationData.shared.lastUpdatedChartTimestamp.removeTimeStamp()
            }
        }
    }
    
    public func updateChartData() {
        do {
            let encoder = JSONEncoder()
            
            let chartDataList = try encoder.encode(ApplicationData.shared.chartDataList)
            
            UserDefaults.standard.set(chartDataList, forKey: "chartData")
            
        } catch {
            print("Unable to Encode Note (\(error))")
        }
        UserDefaults.standard.set("\(Date.now)", forKey: "chartLastUpdated")
    }
    
    public func loadChartData() async -> Date {
        var refreshChartStartDate = Date.now.removeTimeStamp()
        let accountDataList = ApplicationData.shared.data.accountDataList
        for accountData in accountDataList {
            if(accountData.account.accountType.elementsEqual(ConstantUtils.brokerAccountType)) {
                let chartStartDate = await BrokerChartController().loadChartDataForBrokerAccount(accountData: accountData, count: &self.count)
                if(chartStartDate <= refreshChartStartDate) {
                    refreshChartStartDate = chartStartDate
                }
            } else {
                let chartStartDate = await NonBrokerChartController().loadChartDataForNonBrokerAccount(accountData: accountData)
                if(chartStartDate <= refreshChartStartDate) {
                    refreshChartStartDate = chartStartDate
                }
            }
            DispatchQueue.main.async {
                self.count += 1
            }
        }
        return refreshChartStartDate
    }
    
    public func generateChartDataForEachAccountType(isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async {
        let accountDataList = ApplicationData.shared.data.accountDataList
        let accountDataListByAccountType = Dictionary(grouping: accountDataList) {
            if($0.account.active) {
                return $0.account.accountType
            } else {
                return "Inactive Account"
            }
        }
        
        for (accountType, accountDataList) in accountDataListByAccountType {
            if(accountType.elementsEqual(ConstantUtils.brokerAccountType) || accountType.elementsEqual("Inactive Account")) {
                if(accountType.elementsEqual("Inactive Account")) {
                    let chartDataListResult = await generateChartdataForMixedAccounts(accountType: "Inactive Account", accountDataList: accountDataList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
                    ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: "Inactive Account")
                } else {
                    let chartDataListResult = await generateChartDataForMultipleBrokerAccounts(accountType: ConstantUtils.brokerAccountType, accountDataList: accountDataList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
                    ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: ConstantUtils.brokerAccountType)
                }
            } else {
                let chartDataListResult = await generateChartDataForMultipleNonBrokerAccount(accountType: accountType, accountDataList: accountDataList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
                ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: accountType)
            }
            DispatchQueue.main.async {
                self.count += 1
            }
        }
    }
    
    public func generateChartDataForEachWatchList(isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async {
        let watchList = await WatchController().getAllWatchList()
        for watch in watchList {
            let chartDataListResult = generateChartDataForWatchAccount(id: watch.id!, accountIDList: watch.accountID, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
            ApplicationData.shared.chartDataList.updateValue(chartDataListResult, forKey: watch.id!)
            DispatchQueue.main.async {
                self.count += 1
            }
        }
    }
    
    public func generateChartDataForWatchAccount(id: String, accountIDList: [String], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(id)
            })!.value
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        var dummy = [[ChartData]]()
        for accountID in accountIDList {
            let chartData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountID)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = Date.now
        if(isRefreshOperation) {
            startDate = refreshChartStartDate
        } else {
            startDate = dummy.min(by: {
                return $0.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date <= $1.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date
            })?.first?.date.removeTimeStamp() ?? startDate.addingTimeInterval(86400).removeTimeStamp()
        }
        
        while(startDate <= Date.now) {
            var totalValue = 0.0
            for d in dummy {
                totalValue += d.last(where: {
                    return $0.date.removeTimeStamp() <= startDate
                })?.value ?? 0.0
            }
            chartDataListResult.append(ChartData(date: startDate.removeTimeStamp(), value: totalValue))
            startDate.addTimeInterval(86400)
        }
        
        return chartDataListResult
    }
    
    public func generateChartDataForMultipleNonBrokerAccount(accountType: String, accountDataList: [AccountData], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountType)
            })!.value
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        var dummy = [[ChartData]]()
        for accountData in accountDataList {
            let chartData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountData.account.id!)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = Date.now
        if(isRefreshOperation) {
            startDate = refreshChartStartDate
        } else {
            startDate = dummy.min(by: {
                return $0.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date <= $1.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date
            })!.first!.date.removeTimeStamp()
        }
        
        while(startDate <= Date.now) {
            var totalValue = 0.0
            for d in dummy {
                totalValue += d.last(where: {
                    return $0.date.removeTimeStamp() <= startDate
                })?.value ?? 0.0
            }
            chartDataListResult.append(ChartData(date: startDate.removeTimeStamp(), value: totalValue))
            startDate.addTimeInterval(86400)
        }
        
        return chartDataListResult
    }
    
    public func generateChartDataForMultipleBrokerAccounts(accountType: String, accountDataList: [AccountData], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountType)
            })!.value
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        var dummy = [[ChartData]]()
        for accountInBroker in accountDataList {
            let chartData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountInBroker.account.id!)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = Date.now
        if(isRefreshOperation) {
            startDate = refreshChartStartDate
        } else {
            startDate = dummy.min(by: {
                return $0.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date <= $1.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date
            })!.first!.date.removeTimeStamp()
        }
        
        while(startDate <= Date.now) {
            var totalValue = 0.0
            for d in dummy {
                totalValue += d.last(where: {
                    return $0.date.removeTimeStamp() <= startDate
                })?.value ?? 0.0
            }
            chartDataListResult.append(ChartData(date: startDate.removeTimeStamp(), value: totalValue))
            startDate.addTimeInterval(86400)
        }
        return chartDataListResult
    }
    
    public func generateChartdataForMixedAccounts(accountType: String, accountDataList: [AccountData], isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) async -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountType)
            })!.value
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        
        var nonBrokerAccountList = [AccountData]()
        var brokerAccountList = [AccountData]()
        
        for accountData in accountDataList {
            if(accountData.account.accountType.elementsEqual(ConstantUtils.brokerAccountType)) {
                brokerAccountList.append(accountData)
            } else {
                nonBrokerAccountList.append(accountData)
            }
        }
        
        let chartDataForNonBrokerAccountList = await generateChartDataForMultipleNonBrokerAccount(accountType: accountType, accountDataList: nonBrokerAccountList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
        let chartDataForBrokerAccountList = await generateChartDataForMultipleBrokerAccounts(accountType: accountType, accountDataList: brokerAccountList, isRefreshOperation: isRefreshOperation, refreshChartStartDate: refreshChartStartDate)
        
        var startDate = Date.now
        if(isRefreshOperation) {
            startDate = refreshChartStartDate
        } else {
            startDate = getStartDate(chartDataForNonBrokerAccountList: chartDataForNonBrokerAccountList, chartDataForBrokerAccountList: chartDataForBrokerAccountList)
        }
        
        while(startDate <= Date.now) {
            
            var totalValue = 0.0
            
            let transaction1 = chartDataForBrokerAccountList.last(where: {
                return $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
            })
            
            if(transaction1 != nil) {
                totalValue += transaction1!.value
            }
            
            let transaction2 = chartDataForNonBrokerAccountList.last(where: {
                return $0.date.removeTimeStamp() <= startDate.removeTimeStamp()
            })
            
            if(transaction2 != nil) {
                totalValue += transaction2!.value
            }
            chartDataListResult.append(ChartData(date: startDate.removeTimeStamp(), value: totalValue))
            startDate.addTimeInterval(86400)
        }
        return chartDataListResult
    }
    
    public func generateChartDataForOneBrokerAccount(accountData: AccountData, isRefreshOperation: Bool = false, refreshChartStartDate: Date = Date()) -> [ChartData] {
        var chartDataListResult = [ChartData]()
        if(isRefreshOperation) {
            chartDataListResult = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountData.account.id!)
            })!.value
            chartDataListResult.removeAll(where: {
                return $0.date >= refreshChartStartDate
            })
        }
        var dummy = [[ChartData]]()
        for accountInBroker in accountData.accountInBroker {
            let chartData = ApplicationData.shared.chartDataList.first(where: {
                return $0.key.elementsEqual(accountInBroker.accountInBroker.id!)
            })!.value
            
            dummy.append(chartData)
        }
        
        var startDate = Date.now
        if(isRefreshOperation) {
            startDate = refreshChartStartDate
        } else {
            startDate = dummy.min(by: {
                return $0.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date <= $1.min(by: {
                    return $0.date.removeTimeStamp() <= $1.date.removeTimeStamp()
                })!.date
            })!.first!.date.removeTimeStamp()
        }
        
        while(startDate <= Date.now) {
            var totalValue = 0.0
            for d in dummy {
                totalValue += d.last(where: {
                    return $0.date.removeTimeStamp() <= startDate
                })?.value ?? 0.0
            }
            chartDataListResult.append(ChartData(date: startDate.removeTimeStamp(), value: totalValue))
            startDate.addTimeInterval(86400)
        }
        return chartDataListResult
    }
    
    public func getStartDate(chartDataForNonBrokerAccountList: [ChartData], chartDataForBrokerAccountList: [ChartData]) -> Date {
        if(chartDataForBrokerAccountList.count > 0 && chartDataForNonBrokerAccountList.count > 0) {
            return (chartDataForBrokerAccountList.first!.date.removeTimeStamp() >= chartDataForNonBrokerAccountList.first!.date.removeTimeStamp()) ? chartDataForNonBrokerAccountList.first!.date : chartDataForBrokerAccountList.first!.date
        } else if(chartDataForBrokerAccountList.count > 0) {
            return chartDataForBrokerAccountList.first!.date.removeTimeStamp()
        } else if(chartDataForNonBrokerAccountList.count > 0) {
            return chartDataForNonBrokerAccountList.first!.date.removeTimeStamp()
        }
        return Date.now.removeTimeStamp().addingTimeInterval(86400)
    }
    
    public func isAccountAvailableInChartDataList(accountID: String) -> Bool {
        return ApplicationData.shared.chartDataList.contains(where: {
            return $0.key.elementsEqual(accountID)
        })
    }
    
}
