//
//  IncomeTag.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 20/02/23.
//

import Foundation
import FirebaseFirestoreSwift

struct IncomeTag: Codable, Hashable {
    
    @DocumentID var id: String?
    var name: String
    var isdefault: Bool
    
    init(id: String? = "", name: String = "", isdefault: Bool = false) {
        self.id = id
        self.name = name
        self.isdefault = isdefault
    }
}
