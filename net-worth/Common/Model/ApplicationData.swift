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
    
    var dataLoading = false
    
    private init() {
        userId = 0
    }
    
    public static func loadData() async {
        shared.dataLoading = true
        await UserController().addCurrentUser()
        shared.dataLoading = false
    }
}
