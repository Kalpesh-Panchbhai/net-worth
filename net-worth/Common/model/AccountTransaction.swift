//
//  AccountTransaction.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/02/23.
//

import Foundation
import FirebaseFirestoreSwift

struct AccountTrans: Codable, Hashable {
    
    @DocumentID var id: String?
    var timestamp: Date
    var balanceChange: Double
}
