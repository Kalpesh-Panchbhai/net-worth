//
//  User.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/02/23.
//

import Foundation
import FirebaseFirestoreSwift

struct User: Codable {
    
    var id: String
    
    var incomeDataUpdatedDate: Date
    
    init(id: String, incomeDataUpdatedDate: Date =  Date().getEarliestDate()) {
        self.id = id
        self.incomeDataUpdatedDate = incomeDataUpdatedDate
    }

}
