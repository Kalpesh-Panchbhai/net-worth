//
//  Watch.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

struct Watch: Codable, Hashable {
    
    @DocumentID var id: String?
    var accountName: String
    var accountID: [String]
    
    init() {
        self.id = ""
        self.accountName = ""
        self.accountID = [String]()
    }
    
    init(doc: QueryDocumentSnapshot) {
        id = doc.documentID
        accountName = doc[ConstantUtils.watchKeyWatchName] as? String ?? ""
        accountID = doc[ConstantUtils.watchKeyAccountID] as? [String] ?? [String]()
    }
}
