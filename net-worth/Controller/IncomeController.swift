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
    
    public func addIncome(incometype: String, amount: String, date: Date) {
        let newIncome = Income(context: viewContext)
        newIncome.sysid = UUID()
        newIncome.creditedon = date
        newIncome.incometype = incometype
        newIncome.amount = Double((amount as NSString).doubleValue)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    public func getTotalBalance() -> Double {
        var balance = 0.0
        let request = Income.fetchRequest()
        var incomes: [Income] = []
        do{
            incomes = try viewContext.fetch(request)
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        for income in incomes {
            balance += income.amount
        }
        return balance
    }
}
