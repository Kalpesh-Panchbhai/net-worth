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
    
    @Published var incomeTagList = [IncomeTag]()
    
    @Published var incomeTotalAmount = 0.0
    
    private var incomeController = IncomeController()
    
    func getTotalBalance() async {
        do {
            let amount = try await incomeController.fetchTotalAmount()
            DispatchQueue.main.async {
                self.incomeTotalAmount = amount
            }
        } catch {
            print(error)
        }
    }
    
    func getIncomeList() async {
        do {
            let list = try await incomeController.getIncomeList()
            DispatchQueue.main.async {
                self.incomeList = list
            }
        } catch {
            print(error)
        }
    }
    
    func getIncomeTagList() async {
        do {
            let list = try await incomeController.getIncomeTagList()
            DispatchQueue.main.async {
                self.incomeTagList = list
            }
        } catch {
            print(error)
        }
    }
}
