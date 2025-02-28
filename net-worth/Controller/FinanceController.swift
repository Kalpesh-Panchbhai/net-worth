//
//  FinanceController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/22.
//

import Foundation

class FinanceController {
    
    var financeDetailModel = FinanceDetailModel()
    var symbolDetailModel = [SymbolDetailModel]()
    
    public func getSymbolDetail(symbol: String) async -> FinanceDetailModel {
        do {
            self.financeDetailModel = FinanceDetailModel()
            guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/" + symbol) else {
                return financeDetailModel
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return financeDetailModel
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let financeDetailModelResponse = try! decoder.decode(FinanceDetailModelResponse.self, from: data)
            
            for response in financeDetailModelResponse.chart.result {
                self.financeDetailModel.currency = response.meta.currency
                self.financeDetailModel.symbol = response.meta.symbol
                self.financeDetailModel.regularMarketPrice = response.meta.regularMarketPrice
                self.financeDetailModel.chartPreviousClose = response.meta.chartPreviousClose
            }
        }
        catch {
            print(error)
        }
        return financeDetailModel
    }
    
    public func getAllSymbol(search: String) async -> [SymbolDetailModel] {
        do {
            self.symbolDetailModel = [SymbolDetailModel]()
            guard let url = URL(string: "https://query1.finance.yahoo.com/v1/finance/search?q=" + search) else {
                return symbolDetailModel
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return symbolDetailModel
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let symbolDetailResponse = try! decoder.decode(SymbolDetailResponse.self, from: data)
            
            for quote in symbolDetailResponse.quotes {
                var symbol = SymbolDetailModel()
                symbol.exchange = quote.exchange
                symbol.quoteType = quote.quoteType
                symbol.symbol = quote.symbol
                symbol.longname = quote.longname
                
                self.symbolDetailModel.append(symbol)
            }
            
        }
        catch {
            print(error)
        }
        return symbolDetailModel
    }
    
}
