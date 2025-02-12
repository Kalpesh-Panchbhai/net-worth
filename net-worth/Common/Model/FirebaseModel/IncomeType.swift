//
//  IncomeType.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/02/23.
//

import Foundation

struct IncomeType: Codable, Hashable {
    
    var id: Int
    var name: String
    var isdefault: Bool
    
    init(id: Int = 0, name: String = "", isdefault: Bool = false) {
        self.id = id
        self.name = name
        self.isdefault = isdefault
    }
}
