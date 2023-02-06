//
//  CommonController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/02/23.
//

import Foundation
import FirebaseFirestore

class CommonController {
    
    public static func delete(collection: CollectionReference, batchSize: Int = 100) {
        collection.limit(to: batchSize).getDocuments { (docset, error) in
            let docset = docset
            
            let batch = collection.firestore.batch()
            docset?.documents.forEach { batch.deleteDocument($0.reference) }
            
            batch.commit {_ in
                self.delete(collection: collection, batchSize: batchSize)
            }
        }
    }
    
}
