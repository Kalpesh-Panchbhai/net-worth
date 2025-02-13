//
//  ApplicationData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/06/23.
//

import Foundation

struct ApplicationData: Codable {
    
    static var shared = ApplicationData()
    
    var userId: Int
    
    var data: Data2
    var chartDataList: [String: [ChartData]]
    
    var dataLoading = false
    var chartLastUpdated: Date
    
    var symbolDataList = [String: [ChartData]]()
    var totalAccount = Int()
    
    private init() {
        userId = 0
        data = Data2()
        chartDataList = [String: [ChartData]]()
        chartLastUpdated = Date.now
    }
    
    public static func loadData() async {
        shared.dataLoading = true
        await UserController().addCurrentUser()
        shared.dataLoading = false
        await countTotalAccount()
    }
    
    public static func countTotalAccount() async {
        var totalAccount = shared.data.accountDataList.count
        totalAccount += Dictionary(grouping: shared.data.accountDataList) {
            if($0.account.active) {
                return $0.account.accountType
            } else {
                return "Inactive Account"
            }
        }.count
        shared.totalAccount = totalAccount
    }
    
    public static func clear() {
        shared = ApplicationData()
        UserDefaults.standard.removeObject(forKey: "data")
        UserDefaults.standard.removeObject(forKey: "chartData")
        UserDefaults.standard.removeObject(forKey: ConstantUtils.chartLastUpdated)
    }
}
