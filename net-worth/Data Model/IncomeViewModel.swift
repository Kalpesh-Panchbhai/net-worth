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

    func addIncome(income: Income) async {
        do {
            try UserController().getCurrentUserDocument().collection("incomes").addDocument(from: income)
            
            try await self.getIncomeList()
        } catch {
            print(error)
        }
    }
    
    func deleteIncome(income: String) async {
        do {
            try await UserController().getCurrentUserDocument().collection("incomes").document(income).delete()
        } catch {
            print(error)
        }
    }
    
    func getTotalBalance() async {
        do {
            try await UserController().getCurrentUserDocument().collection(ConstantUtils().incomeCollectionName).getDocuments { snapshot, error in
                if error == nil {
                    if let snapshot = snapshot {
                        snapshot.documents.forEach { doc in
                            self.incomeTotalAmount = self.incomeTotalAmount + (doc["amount"] as? Double ?? 0.0)
                        }
                    }
                } else {
                    
                }
            }
        } catch {
            print(error)
        }
    }
    
    func getIncomeList() async {
        do {
            try await UserController().getCurrentUserDocument()
                .collection("incomes")
                .getDocuments { snapshot, error in
                    if error == nil {
                        if let snapshot = snapshot {
                            self.incomeList = snapshot.documents.map { doc in
                                return Income(id: doc.documentID,
                                               amount: doc["amount"] as? Double ?? 0.0,
                                               creditedon: doc["creditedon"] as? Date ?? Date(),
                                               currency: doc["currency"] as? String ?? "",
                                               incometype: doc["incometype"] as? String ?? "")
                                
                            }
                        }
                    } else {
                        
                    }
                }
        } catch {
            print(error)
        }
    }
}
