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
        let newIncome = Income(amount: Double(amount) ?? 0.0, creditedon: date, currency: currency, incometype: incometype)
        try await incomeViewModel.addIncome(income: newIncome)
    }
    
}
