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
    
    init(id: String = "", timestamp: Date = Date(), symbol: String = "", name: String = "", currentUnit: Double = 0.0) {
        self.id = id
        self.timestamp = timestamp
        self.symbol = symbol
        self.name = name
        self.currentUnit = currentUnit
    }
    
    init(doc: QueryDocumentSnapshot) {
        self.id = doc.documentID
        self.timestamp = (doc[ConstantUtils.accountBrokerKeyTimeStamp] as? Timestamp)?.dateValue() ?? Date()
        self.symbol = doc[ConstantUtils.accountBrokerKeySymbol] as? String ?? ""
        self.name = doc[ConstantUtils.accountBrokerKeyName] as? String ?? ""
        self.currentUnit = doc[ConstantUtils.accountBrokerKeyCurrentUnit] as? Double ?? 0.0
    }
    
    init(doc1: DocumentSnapshot) {
        self.id = doc1.documentID
        self.timestamp = (doc1[ConstantUtils.accountBrokerKeyTimeStamp] as? Timestamp)?.dateValue() ?? Date()
        self.symbol = doc1[ConstantUtils.accountBrokerKeySymbol] as? String ?? ""
        self.name = doc1[ConstantUtils.accountBrokerKeyName] as? String ?? ""
        self.currentUnit = doc1[ConstantUtils.accountBrokerKeyCurrentUnit] as? Double ?? 0.0
    }
}
