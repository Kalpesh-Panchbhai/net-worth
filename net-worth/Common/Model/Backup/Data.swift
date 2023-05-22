//
//  Data.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

struct Data: Codable {
    
    var incomeTag: [IncomeTagData]
    var incomeType: [IncomeTypeData]
    var income: [IncomeData]
    var account: [AccountData]
    var watch: [WatchData]
    
    init() {
        self.incomeTag = [IncomeTagData]()
        self.incomeType = [IncomeTypeData]()
        self.income = [IncomeData]()
        self.account = [AccountData]()
        self.watch = [WatchData]()
    }
}
