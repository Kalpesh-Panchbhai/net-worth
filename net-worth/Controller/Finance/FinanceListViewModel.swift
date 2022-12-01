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
    
    func search(name: String) async {
        do {
            financeModels = try await FinanceController().getAllSymbols(searchTerm: name)
        } catch {
            print(error)
        }
    }
}
