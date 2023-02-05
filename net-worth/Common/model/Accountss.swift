//
//  Account.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation
import FirebaseFirestoreSwift

struct Accountss: Codable, Hashable {
    
    @DocumentID var id: String?
    var accountType: String
    var accountName: String
    var currentBalance: Double
    var totalShares: Double
    var paymentReminder: Bool
    var paymentDate: Int
    var symbol: String
    var currency: String
    
}
