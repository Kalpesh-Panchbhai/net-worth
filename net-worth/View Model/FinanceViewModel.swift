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
}
