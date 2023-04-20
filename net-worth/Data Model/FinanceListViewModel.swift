//
//  FinanceListViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/22.
//

import Foundation

@MainActor
class FinanceListViewModel: ObservableObject {
    
    @Published var financeDetailModel = FinanceDetailModel()
    
    @Published var financeDetailModelWithRange = FinanceDetailModel()
    
    func getSymbolDetailsWithRange(symbol: String) async {
        do {
            financeDetailModel = try await FinanceController().getSymbolDetailsWithRange(symbol: symbol)
        } catch {
            print(error)
        }
    }
}
