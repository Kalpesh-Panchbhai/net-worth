//
//  StringExtension.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 22/11/22.
//

import Foundation

extension StringProtocol {
    
    var double: Double? { Double(self) }
    var float: Float? { Float(self) }
    var integer: Int? { Int(self) }
}

extension String {
    
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
    
    func toDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter.date(from: self)!
    }
    
    func toFullDateFormat() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yyyy 'at' HH:mm:ss aa"
        return dateFormatter.date(from: self)!
    }
}
