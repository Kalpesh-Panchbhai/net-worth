//
//  Data.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 23/12/23.
//

import Foundation

struct Data: Codable {
    
    var userData: User
    
    var incomeDataList: [IncomeData]
    var incomeDataListUpdatedDate: Date
    
    public init() {
        userData = User()
        incomeDataList = [IncomeData]()
        incomeDataListUpdatedDate = Date().getEarliestDate().addingTimeInterval(-86400)
    }
}
