//
//  FinanceController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/22.
//

import Foundation

class FinanceController {
    
    private var dataCaptured = false
    
    private var financeModel = [FinanceModel]()
    
    private var financeDetailModel = FinanceDetailModel()
    
    public func getAllSymbols(searchTerm: String) async throws -> [FinanceModel] {
        
        dataCaptured = false
        var url = "https://query1.finance.yahoo.com/v1/finance/search?q=" + searchTerm
        url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        guard let url = URL(string: url) else {
            return financeModel
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            return financeModel
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let financeModelResponse = try! decoder.decode(FinanceModelResponse.self, from: data)
        self.financeModel = financeModelResponse.quotes.compactMap({
            var financeModel = FinanceModel()
            financeModel.shortname = $0.shortname
            financeModel.quoteType = $0.quoteType
            financeModel.symbol = $0.symbol
            financeModel.typeDisp = $0.typeDisp
            financeModel.longname = $0.longname
            financeModel.exchDisp = $0.exchDisp
            
            return financeModel
        })
        
        for i in 0..<financeModel.count {
            financeModel[i].financeDetailModel = getSymbolDetail(symbol: financeModel[i].symbol!)
        }
        return financeModel
    }
    
    public func getSymbolDetails(symbol: String) async throws -> FinanceDetailModel {
        
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
            self.financeDetailModel.symbol = response.meta.currency
            self.financeDetailModel.regularMarketPrice = response.meta.regularMarketPrice
            self.financeDetailModel.chartPreviousClose = response.meta.chartPreviousClose
            self.financeDetailModel.oneDayChange = (self.financeDetailModel.regularMarketPrice ?? 0.0) - (self.financeDetailModel.chartPreviousClose ?? 0.0)
        }
        
        return financeDetailModel
    }
    
    public func getSymbolDetail(symbol: String) -> FinanceDetailModel {
        
        dataCaptured = false
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/" + symbol) else {
            return financeDetailModel
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200 == httpResponse.statusCode else {
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let financeDetailModelResponse = try! decoder.decode(FinanceDetailModelResponse.self, from: data)
            
            for response in financeDetailModelResponse.chart.result {
                self.financeDetailModel.currency = response.meta.currency
                self.financeDetailModel.symbol = response.meta.currency
                self.financeDetailModel.regularMarketPrice = response.meta.regularMarketPrice
                self.financeDetailModel.chartPreviousClose = response.meta.chartPreviousClose
                self.financeDetailModel.oneDayChange = (self.financeDetailModel.regularMarketPrice ?? 0.0) - (self.financeDetailModel.chartPreviousClose ?? 0.0)
            }
            self.dataCaptured = true
        }
        
        task.resume()
        
        while(!dataCaptured) {}
        
        return financeDetailModel
    }
}
