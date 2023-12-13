//
//  AccountBroker.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import Foundation
import FirebaseFirestoreSwift

struct AccountBroker: Codable, Hashable {
    
    @DocumentID var id: String?
    var timestamp: Date
    var symbol: String
    var name: String
    var currentUnit: Double
    
    init(id: String = "", timestamp: Date = Date(), symbol: String = "", name: String = "", currentUnit: Double = 0.0) {
        self.id = id
        self.timestamp = timestamp
        self.symbol = symbol
        self.name = name
        self.currentUnit = currentUnit
    }
}