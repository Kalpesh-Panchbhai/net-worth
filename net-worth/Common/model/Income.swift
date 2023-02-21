//
//  Income.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/02/23.
//

import Foundation
import FirebaseFirestoreSwift

struct Income: Codable, Hashable {
    
    @DocumentID var id: String?
    var amount: Double
    var creditedOn: Date
    var currency: String
    var incomeType: String
    var tag: String
}
