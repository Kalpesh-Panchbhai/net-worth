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
    
    @Published var multipleSymbolList = [FinanceDetailModel]()
    @Published var multipleCurrencyList = [FinanceDetailModel]()
    
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
    
    func getMultipleSymbolDetail(brokerAccountList: [AccountInBroker], range: String) async {
        var multipleSymbolList = [FinanceDetailModel]()
        var multipleCurrencyList = [FinanceDetailModel]()
        for brokerAccount in brokerAccountList {
            let symbol = await financeController.getSymbolDetail(symbol: brokerAccount.symbol, range: getNextValidRange(range: range))
            multipleSymbolList.append(symbol)
            if(symbol.currency != SettingsController().getDefaultCurrency().code) {
                let currency = await financeController.getCurrencyDetail(accountCurrency: SettingsController().getDefaultCurrency().code, range: getNextValidRange(range: range))
                multipleCurrencyList.append(currency)
            } else {
                multipleCurrencyList.append(FinanceDetailModel())
            }
        }
        
        let updatedMultipleSymbolList = multipleSymbolList
        let updatedMultipleCurrencyList = multipleCurrencyList
        DispatchQueue.main.async {
            self.multipleSymbolList = updatedMultipleSymbolList
            self.multipleCurrencyList = updatedMultipleCurrencyList
        }
    }
    
    func getSymbolDetail(symbol: String, range: String) async {
        let symbol = await financeController.getSymbolDetail(symbol: symbol, range: getNextValidRange(range: range))
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
    
    private func getNextValidRange(range: String) -> String {
        if(range.elementsEqual(ConstantUtils.oneMonthRange)) {
            return "3mo"
        } else if(range.elementsEqual(ConstantUtils.threeMonthRange)) {
            return "6mo"
        } else if(range.elementsEqual(ConstantUtils.sixMonthRange)) {
            return "1y"
        } else if(range.elementsEqual(ConstantUtils.oneYearRange)) {
            return "2y"
        } else if(range.elementsEqual(ConstantUtils.twoYearRange)) {
            return "5y"
        } else if(range.elementsEqual(ConstantUtils.fiveYearRange)) {
            return "10y"
        }
        return ""
    }
}
