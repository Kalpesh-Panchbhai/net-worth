//
//  DateExtension.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import Foundation

extension Date {
    
    func format() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: self)
    }
    
    func getDateAndFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    func getTimeAndFormat() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: self)
    }
    
    func removeTimeStamp() -> Date {
        let date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: self))
        return date ?? Date()
    }
}
