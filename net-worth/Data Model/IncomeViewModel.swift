//
//  IncomeViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/02/23.
//

import Foundation
import Firebase
import FirebaseFirestore

class IncomeViewModel: ObservableObject {
    
    @Published var incomeList = [Income]()
    
    @Published var incomeTotalAmount = 0.0
    
    private var incomeController = IncomeController()
    
    func getTotalBalance() async {
        do {
            incomeTotalAmount = try await incomeController
                .fetchTotalAmount()
        } catch {
            print(error)
        }
    }
    
    func getIncomeList() async {
        do {
            self.incomeList = try await incomeController.getIncomeList()
        } catch {
            print(error)
        }
    }
}
