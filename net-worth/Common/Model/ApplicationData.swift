//
//  ApplicationData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/06/23.
//

import Foundation

struct ApplicationData: Codable {
    
    static var shared = ApplicationData()
    
    var userId: String
        
    var dataLoading = false
    
    private init() {
        userId = ""
    }
    
    public static func loadData() async {
        shared.dataLoading = true
        await UserController().addCurrentUser()
        shared.dataLoading = false
    }

    
    public static func clear() {
        shared = ApplicationData()
    }
}
