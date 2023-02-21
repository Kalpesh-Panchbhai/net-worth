//
//  FinanceDetailMode.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/22.
//

import Foundation

struct FinanceDetailModel: Hashable {
    
    var currency: String? = ""
    
    var symbol: String? = ""
    
    var regularMarketPrice: Double? = 0.0
    
    var chartPreviousClose: Double? = 0.0
    
    var oneDayChange: Double? = 0.0
    
    var oneDayPercentChange: Double? = 0.0
    
    var timestamp: [Int?] = []
    
    var valueAtTimestamp: [Double?] = []
    
}

struct FinanceDetailModelResponse: Decodable {
    
    let chart: FinanceDetailResultResponse
}

struct FinanceDetailResultResponse: Decodable {
    
    let result: [FinanceDetailMetaResponse]
    
}

struct FinanceDetailIndicatorResponse: Decodable {
    
    let quote: [FinanceDetailQuoteResponse]
    
}

struct FinanceDetailQuoteResponse: Decodable {
    
    let close: [Double?]
}

struct FinanceDetailMetaResponse: Decodable {
    
    let meta: FinanceDetailMetaDetailResponse
    
    let timestamp: [Int]
    
    let indicators: FinanceDetailIndicatorResponse
    
}

struct FinanceDetailMetaDetailResponse: Decodable {
    
    let currency: String?
    
    let symbol: String?
    
    let regularMarketPrice: Double?
    
    let chartPreviousClose: Double?
    
}
