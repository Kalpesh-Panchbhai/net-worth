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
    
    private init() {
        incomeList = [Income]()
        incomeListUpdatedDate = Date().getEarliestDate()
    }
}
