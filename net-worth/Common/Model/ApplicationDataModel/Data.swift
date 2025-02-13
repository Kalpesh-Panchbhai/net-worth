//
//  Data.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 23/12/23.
//

import Foundation

struct Data2: Codable {
    
    var userData: User
    
    var incomeDataList: [IncomeRestModel]
    var incomeDataListUpdatedDate: Date
    
    var accountDataList: [AccountData]
    var accountDataListUpdatedDate: Date
    
    public init() {
        userData = User()
        
        incomeDataList = [IncomeRestModel]()
        incomeDataListUpdatedDate = Date().getEarliestDate()
        
        accountDataList = [AccountData]()
        accountDataListUpdatedDate = Date().getEarliestDate()
    }
}
