//
//  AccountInBroker.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct AccountInBroker: Codable, Hashable {
    
    var id: String?
    var timestamp: Date
    var symbol: String
    var name: String
    var currentUnit: Double
    var lastUpdated: Date
    var deleted: Bool
    
    init(id: String? = nil, timestamp: Date = Date(), symbol: String = "", name: String = "", currentUnit: Double = 0.0, lastUpdated: Date = Date.now, deleted: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.symbol = symbol
        self.name = name
        self.currentUnit = currentUnit
        self.lastUpdated = lastUpdated
        self.deleted = deleted
    }
    
    init(doc: QueryDocumentSnapshot) {
        self.id = doc.documentID
        self.timestamp = (doc[ConstantUtils.accountBrokerKeyTimeStamp] as? Timestamp)?.dateValue() ?? Date()
        self.symbol = doc[ConstantUtils.accountBrokerKeySymbol] as? String ?? ""
        self.name = doc[ConstantUtils.accountBrokerKeyName] as? String ?? ""
        self.currentUnit = doc[ConstantUtils.accountBrokerKeyCurrentUnit] as? Double ?? 0.0
        self.lastUpdated = (doc[ConstantUtils.accountBrokerKeyLastUpdated] as? Timestamp)?.dateValue() ?? Date()
        self.deleted = doc[ConstantUtils.accountBrokerKeyDeleted] as? Bool ?? false
    }
}
