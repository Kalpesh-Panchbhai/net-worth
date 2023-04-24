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
    var type: String
    var tag: String
    
    var avg: Double = 0.0
    var cumulative: Double = 0.0
}
