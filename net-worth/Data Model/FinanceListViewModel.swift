//
//  FinanceListViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/22.
//

import Foundation

@MainActor
class FinanceListViewModel: ObservableObject {
    
    @Published var financeModels: [FinanceModel] = []
    
    @Published var financeDetailModel = FinanceDetailModel()
    
    func getAllSymbols(searchTerm: String) async {
        do {
            financeModels = try await FinanceController().getAllSymbols(searchTerm: searchTerm)
        } catch {
            print(error)
        }
    }
    
    func getSymbolDetails(symbol: String) async {
        do {
            financeDetailModel = try await FinanceController().getSymbolDetails(symbol: symbol)
        } catch {
            print(error)
        }
    }
}
