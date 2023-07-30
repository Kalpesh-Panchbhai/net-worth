//
//  CommonController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/02/23.
//

import Foundation
import Charts
import FirebaseFirestore

class CommonController {
    
    public static func parseAxisValue(value: AxisValue) -> String? {
        let input = String(describing: value)
        let regex = /\((\d*.0)|\((0)|\((-\d*.0)/
        
        if let match = input.firstMatch(of: regex) {
            return "\(match.1 ?? match.2 ?? match.3 ?? "")"
        }
        return nil
    }
    
    public static func abbreviateAxisValue(string: String) -> String {
        let decimal = Decimal(string: string)
        if decimal == nil {
            return string
        } else {
            if abs(decimal!) > 999999999999.9 {
                return "\(decimal! / 1000000000000.0)t"
            } else if abs(decimal!) > 999999999.9 {
                return "\(decimal! / 1000000000.0)b"
            } else if abs(decimal!) > 999999.9 {
                return "\(decimal! / 1000000.0)m"
            } else if abs(decimal!) > 999.9 {
                return "\(decimal! / 1000.0)k"
            } else {
                return "\(decimal!)"
            }
        }
    }
    
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
    
    public static func getGrowthPercentage(previousBalance: Double, currentBalance: Double) -> String {
        
        var percentage = previousBalance.distance(to: currentBalance) / previousBalance * 100
        
        if((previousBalance.distance(to: currentBalance) > 0 && percentage < 0) || (previousBalance.distance(to: currentBalance) < 0 && percentage > 0)) {
            percentage = percentage * -1.0
        } else if(String(percentage).elementsEqual("-0")) {
            percentage = percentage * -1.0
        } else if(percentage.isZero && percentage.sign == .minus) {
            percentage = percentage * -1.0
        }
        return percentage.withCommas(decimalPlace: 2) + "%"
    }
}
