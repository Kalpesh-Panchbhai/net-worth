//
//  DateExtension.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import Foundation

extension Date {
    
    func getEarliestDate() -> Date {
        var dateComponent = DateComponents();
        dateComponent.day = 1
        dateComponent.month = 1
        dateComponent.year = 1900
        return Calendar.current.date(from: dateComponent)!
    }
    
    func format() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: self)
    }
    
    func formatImportExportTimeStamp() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter.string(from: self)
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
    
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    
    func getDateComponents() -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: self)
    }
}
