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
    var taxPaid: Double
    var creditedOn: Date
    var currency: String
    var type: String
    var tag: String
    
    var avgAmount: Double = 0.0
    var avgTaxPaid: Double = 0.0
    var cumulativeAmount: Double = 0.0
    var cumulativeTaxPaid: Double = 0.0
    
    var animate: Bool = false
}
