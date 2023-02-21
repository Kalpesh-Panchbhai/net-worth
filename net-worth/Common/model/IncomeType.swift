//
//  IncomeType.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/02/23.
//

import Foundation
import FirebaseFirestoreSwift

struct IncomeType: Codable, Hashable {
    
    @DocumentID var id: String?
    var name: String
    
    init(id: String? = nil, name: String) {
        self.id = id
        self.name = name
    }
    
    init() {
        self.name = ""
        self.id = ""
    }
}
