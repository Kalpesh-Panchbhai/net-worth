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

    func addIncome(income: Income) {
        do {
            try UserController().getCurrentUserDocument().collection(ConstantUtils().incomeCollectionName).addDocument(from: income)
            
            self.getIncomeList()
        } catch {
            print(error)
        }
    }
    
    func deleteIncome(income: String) async {
        do {
            try await UserController().getCurrentUserDocument().collection(ConstantUtils().incomeCollectionName).document(income).delete()
        } catch {
            print(error)
        }
    }
    
    func getTotalBalance() async {
        do {
            incomeTotalAmount = try await IncomeController().fetchTotalAmount()
        } catch {
            print(error)
        }
    }
    
    func getIncomeList() {
        UserController().getCurrentUserDocument()
                .collection(ConstantUtils().incomeCollectionName)
                .getDocuments { snapshot, error in
                    if error == nil {
                        if let snapshot = snapshot {
                            self.incomeList = snapshot.documents.map { doc in
                                return Income(id: doc.documentID,
                                               amount: doc["amount"] as? Double ?? 0.0,
                                               creditedon: (doc["creditedon"] as? Timestamp)?.dateValue() ?? Date(),
                                               currency: doc["currency"] as? String ?? "",
                                               incometype: doc["incometype"] as? String ?? "")
                            }
                        }
                    } else {
                        
                    }
                }
    }
}
