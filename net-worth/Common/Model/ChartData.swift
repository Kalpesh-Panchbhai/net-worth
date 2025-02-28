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
    
    private enum CodingKeys: String, CodingKey {
        case date, value
    }
    
    init(date: Date = Date(), value: Double = 0.0) {
        self.date = date
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var stringDate = try container.decode(String.self, forKey: .date)
        date = stringDate.toFullDateFormat()
        value = try container.decode(Double.self, forKey: .value)
    }
}
