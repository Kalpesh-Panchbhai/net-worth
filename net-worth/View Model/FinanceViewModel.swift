//
//  FinanceViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 30/11/23.
//

import Foundation

class FinanceViewModel: ObservableObject {
    
    var financeController = FinanceController()
    
    @Published var symbolList = [SymbolDetailModel]()
    @Published var symbol = FinanceDetailModel()
    @Published var currency = FinanceDetailModel()
    
    func getAllSymbol(search: String) async {
        let symbolList = await financeController.getAllSymbol(search: search)
        DispatchQueue.main.async {
            self.symbolList = symbolList
        }
    }
    
    func getSymbolDetail(symbol: String) async {
        let symbol = await financeController.getSymbolDetail(symbol: symbol)
        DispatchQueue.main.async {
            self.symbol = symbol
        }
    }
    
    func getSymbolDetail(symbol: String, range: String) async {
        let symbol = await financeController.getSymbolDetail(symbol: symbol, range: getValidRange(range: range))
        if(symbol.currency != SettingsController().getDefaultCurrency().code) {
            let currency = await financeController.getCurrencyDetail(accountCurrency: SettingsController().getDefaultCurrency().code, range: getNextValidRange(range: range))
            DispatchQueue.main.async {
                self.currency = currency
            }
        }
        DispatchQueue.main.async {
            self.symbol = symbol
        }
    }
    
    private func getValidRange(range: String) -> String {
        if(range.elementsEqual("1M")) {
            return "1mo"
        } else if(range.elementsEqual("3M")) {
            return "3mo"
        } else if(range.elementsEqual("6M")) {
            return "6mo"
        } else if(range.elementsEqual("1Y")) {
            return "1y"
        } else if(range.elementsEqual("2Y")) {
            return "2y"
        } else if(range.elementsEqual("5Y")) {
            return "5y"
        }
        return ""
    }
    
    private func getNextValidRange(range: String) -> String {
        if(range.elementsEqual("1M")) {
            return "3mo"
        } else if(range.elementsEqual("3M")) {
            return "6mo"
        } else if(range.elementsEqual("6M")) {
            return "1y"
        } else if(range.elementsEqual("1Y")) {
            return "2y"
        } else if(range.elementsEqual("2Y")) {
            return "5y"
        } else if(range.elementsEqual("5Y")) {
            return "max"
        }
        return ""
    }
}
