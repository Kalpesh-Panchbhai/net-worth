//
//  SymbolDetailModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 30/11/23.
//

import Foundation

struct SymbolDetailModel: Hashable {
    
    var exchange: String? = ""
    
    var quoteType: String? = ""
    
    var symbol: String? = ""
    
    var longname: String? = ""
    
}

struct SymbolDetailResponse: Decodable {
    let quotes: [SymbolDetailQuoteResponse]
}

struct SymbolDetailQuoteResponse: Decodable {
    
    let exchange: String?
    
    let quoteType: String?
    
    let symbol: String?
    
    let longname: String?
    
}
