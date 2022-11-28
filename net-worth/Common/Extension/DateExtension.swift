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
}
