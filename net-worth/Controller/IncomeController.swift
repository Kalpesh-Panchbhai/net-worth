//
//  IncomeController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import Foundation
import SwiftUI

class IncomeController {
    
    let viewContext = PersistenceController.shared.container.viewContext
    
    var incomeViewModel = IncomeViewModel()
    
    public func addIncome(incometype: String, amount: String, date: Date, currency: String) async {
        let newIncome = Income(amount: Double(amount) ?? 0.0, creditedOn: date, currency: currency, incomeType: incometype)
        incomeViewModel.addIncome(income: newIncome)
    }
    
    public func fetchTotalAmount() async throws -> Double {
        var total = 0.0
        try await withUnsafeThrowingContinuation { continuation in
            UserController()
                .getCurrentUserDocument()
                .collection(ConstantUtils.incomeCollectionName)
                .getDocuments { snapshot, error in
                    if error  == nil {
                        if let snapshot = snapshot {
                            snapshot.documents.forEach { doc in
                                total += doc[ConstantUtils.incomeKeyAmount] as? Double ?? 0.0
                            }
                            continuation.resume()
                        }
                    }
                }
        }
        return total
    }
    
}

