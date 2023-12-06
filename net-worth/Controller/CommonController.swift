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
    
    public static func CalculateCAGR(firstBalance: Double, lastBalance: Double, days: Double) -> String {
        let firstBalance = firstBalance
        let lastBalance = lastBalance
        let years = days/365
        
        let cagr = (pow((lastBalance/firstBalance), 1/years) - 1) * 100
        
        return Double(cagr).withCommas(decimalPlace: 2) + "%"
    }
    
    public static func getIntervalForDateRange(date: Date, range: String) -> Date {
        var date = date
        if(range.elementsEqual("1M")) {
            date = Timestamp.init(date: date.addingTimeInterval(86400)).dateValue()
        } else if(range.elementsEqual("3M")) {
            date = Timestamp.init(date: date.addingTimeInterval(86400 * 2)).dateValue()
        } else if(range.elementsEqual("6M")) {
            date = Timestamp.init(date: date.addingTimeInterval(86400 * 3)).dateValue()
        } else if(range.elementsEqual("1Y")) {
            date = Timestamp.init(date: date.addingTimeInterval(86400 * 4)).dateValue()
        } else if(range.elementsEqual("2Y")) {
            date = Timestamp.init(date: date.addingTimeInterval(86400 * 5)).dateValue()
        } else if(range.elementsEqual("5Y")) {
            date = Timestamp.init(date: date.addingTimeInterval(86400 * 6)).dateValue()
        } else if(range.elementsEqual("All")) {
            date = Timestamp.init(date: date.addingTimeInterval(86400 * 7)).dateValue()
        }
        return date.removeTimeStamp()
    }
    
    public static func getStartDateForRange(range: String) -> Date {
        var date = Timestamp().dateValue().removeTimeStamp()
        if(range.elementsEqual("1M")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-2592000)).dateValue()
        } else if(range.elementsEqual("3M")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-7776000)).dateValue()
        } else if(range.elementsEqual("6M")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-15552000)).dateValue()
        } else if(range.elementsEqual("1Y")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-31104000)).dateValue()
        } else if(range.elementsEqual("2Y")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-62208000)).dateValue()
        } else if(range.elementsEqual("5Y")) {
            date = Timestamp.init(date: Date.now.addingTimeInterval(-155520000)).dateValue()
        }
        return date.removeTimeStamp()
    }
}
