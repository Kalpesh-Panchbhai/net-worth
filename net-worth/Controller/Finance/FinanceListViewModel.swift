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
    
    @Published var totalBalance = BalanceModel()
    
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
    
    func getTotalBalance() async {
        do {
            totalBalance = try await AccountController().fetchTotalBalance()
        } catch {
            print(error)
        }
    }
}
