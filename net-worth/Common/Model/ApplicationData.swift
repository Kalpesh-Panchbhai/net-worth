//
//  ApplicationData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/06/23.
//

import Foundation

struct ApplicationData: Codable {

    static var shared = ApplicationData()
    
    var incomeList: [Income]
    var incomeListUpdatedDate: Date
    
    var accountList: [Account: [AccountTransaction]]
    var accountListUpdatedDate: Date
    
    private init() {
        incomeList = [Income]()
        incomeListUpdatedDate = Date().getEarliestDate().addingTimeInterval(-86400)
        
        accountList = [Account: [AccountTransaction]]()
        accountListUpdatedDate = Date().getEarliestDate().addingTimeInterval(-86400)
    }
    
    public static func clear() {
        shared = ApplicationData()
    }
}
