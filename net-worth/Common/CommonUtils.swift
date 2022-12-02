//
//  CommonUtils.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 02/12/22.
//

import Foundation

enum ValueType {
    case percentage, literal
}

//enum Currency_symbol_map: String {
//
//    case AED
//    case INR
//    case USD
//
//    var rawValue: String {
//        switch self {
//        case .USD: return "$"
//        case .INR: return "*"
//        case .AED: return "#"
//        }
//    }
//}

struct Currency: Hashable, Encodable, Decodable {
    
    var code: String
    var symbol: String
    var name: String
    
    init(code: String, symbol: String, name: String) {
        self.code = code
        self.symbol = symbol
        self.name = name
    }
    
    init() {
        code = ""
        symbol = ""
        name = ""
    }
}

struct CurrencyList {
    
    var currencyList = [Currency]()
    
    init() {
        currencyList.append(Currency(code: "AED", symbol: "Dh", name: "United Arab Emirates dirham"))
        currencyList.append(Currency(code: "AFN", symbol: "Af", name: "Afghan afghani"))
        currencyList.append(Currency(code: "ALL", symbol: "Lek", name: "Albanian lek"))
        currencyList.append(Currency(code: "AMD", symbol: "֏", name: "Armenian dram"))
        currencyList.append(Currency(code: "ANG", symbol: "ƒ", name: "Netherlands Antillean guilder"))
        currencyList.append(Currency(code: "AOA", symbol: "Kz", name: "Angolan kwanza"))
        currencyList.append(Currency(code: "ARS", symbol: "$", name: "Argentine peso"))
        currencyList.append(Currency(code: "AUD", symbol: "$", name: "Australian dollar"))
        currencyList.append(Currency(code: "AWG", symbol: "ƒ", name: "Aruban florin"))
        currencyList.append(Currency(code: "AZN", symbol: "₼", name: "Azerbaijani manat"))
        currencyList.append(Currency(code: "BAM", symbol: "KM", name: "Bosnia and Herzegovina convertible mark"))
        currencyList.append(Currency(code: "BBD", symbol: "$", name: "Barbadian dollar"))
        currencyList.append(Currency(code: "BDT", symbol: "৳", name: "Bangladeshi taka"))
        currencyList.append(Currency(code: "BGN", symbol: "Lev", name: "Bulgarian lev"))
        currencyList.append(Currency(code: "BHD", symbol: "BD", name: "Bahraini dinar"))
        currencyList.append(Currency(code: "BIF", symbol: "Fr", name: "Burundian franc"))
        currencyList.append(Currency(code: "BMD", symbol: "$", name: "Bermudian dollar"))
        currencyList.append(Currency(code: "BND", symbol: "$", name: "Brunei dollar"))
        currencyList.append(Currency(code: "EUR", symbol: "€", name: "Euro"))
        currencyList.append(Currency(code: "EUR", symbol: "£", name: "Sterling"))
        currencyList.append(Currency(code: "INR", symbol: "₹", name: "Indian rupee"))
        currencyList.append(Currency(code: "USD", symbol: "$", name: "US Dollar"))
    }
    
    func getSymbolWithCode(code: String) -> Currency {
        return currencyList.first {
            $0.code == code
        } ?? Currency()
    }
}
