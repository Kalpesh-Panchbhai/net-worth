//
//  Finance.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/22.
//

import Foundation

struct FinanceModel: Hashable {
    
    var shortname: String? = ""
    
    var quoteType: String? = ""
    
    var symbol: String? = ""
    
    var longname: String? = ""
    
    var exchDisp: String? = ""
    
    var financeDetailModel: FinanceDetailModel?
}

struct FinanceModelResponse: Decodable {
 
    let quotes: [FinanceQuotesResponse]
}

struct FinanceQuotesResponse: Decodable {
    
    let shortname: String?
    
    let quoteType: String?
    
    let symbol: String?
    
    let longname: String?
    
    let exchDisp: String?
    
}
