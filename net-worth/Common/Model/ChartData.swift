//
//  ChartData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 18/02/23.
//

import Foundation

struct ChartData: Codable, Hashable {
    
    var date: Date
    
    var value: Double
    
    var future: Bool = false
}
