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
    
    public func getSymbolDetails(accountCurrency: String) async throws -> FinanceDetailModel {
        
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/" + accountCurrency + "USD" + "=X") else {
            return financeDetailModel
        }
        
        var (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            return financeDetailModel
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        var financeDetailModelResponse = try! decoder.decode(FinanceDetailModelResponse.self, from: data)
        
        for response in financeDetailModelResponse.chart.result {
            self.financeDetailModel.currency = response.meta.currency
            self.financeDetailModel.symbol = response.meta.currency
            self.financeDetailModel.regularMarketPrice = response.meta.regularMarketPrice
            self.financeDetailModel.chartPreviousClose = response.meta.chartPreviousClose
            self.financeDetailModel.oneDayChange = (self.financeDetailModel.regularMarketPrice ?? 0.0) - (self.financeDetailModel.chartPreviousClose ?? 0.0)
            self.financeDetailModel.oneDayPercentChange = (self.financeDetailModel.oneDayChange ?? 1.0) / (self.financeDetailModel.regularMarketPrice ?? 1.0) * 100
        }
        
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/USD" + SettingsController().getDefaultCurrency().code + "=X") else {
            return financeDetailModel
        }
        
        (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            return financeDetailModel
        }
        
        financeDetailModelResponse = try! decoder.decode(FinanceDetailModelResponse.self, from: data)
        
        for response in financeDetailModelResponse.chart.result {
            self.financeDetailModel.currency = response.meta.currency
            self.financeDetailModel.symbol = response.meta.currency
            self.financeDetailModel.regularMarketPrice = (response.meta.regularMarketPrice ?? 1.0) * (self.financeDetailModel.regularMarketPrice ?? 1.0)
            self.financeDetailModel.chartPreviousClose = (response.meta.chartPreviousClose ?? 1.0) * (self.financeDetailModel.chartPreviousClose ?? 1.0)
            self.financeDetailModel.oneDayChange = (self.financeDetailModel.regularMarketPrice ?? 0.0) - (self.financeDetailModel.chartPreviousClose ?? 0.0)
            self.financeDetailModel.oneDayPercentChange = (self.financeDetailModel.oneDayChange ?? 1.0) / (self.financeDetailModel.regularMarketPrice ?? 1.0) * 100
            
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
                self.financeDetailModel.oneDayPercentChange = (self.financeDetailModel.oneDayChange ?? 1.0) / (self.financeDetailModel.regularMarketPrice ?? 1.0) * 100
            }
            self.dataCaptured = true
        }
        
        task.resume()
        
        while(!dataCaptured) {}
        
        return financeDetailModel
    }
}
