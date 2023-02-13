//
//  IncomeController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import FirebaseFirestore

class IncomeController {
    
    private func getIncomeCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.incomeCollectionName)
    }
    
    public func addIncome(incometype: String, amount: String, date: Date, currency: String) async {
        let newIncome = Income(amount: Double(amount) ?? 0.0, creditedOn: date, currency: currency, incomeType: incometype)
        do {
            let documentID = try getIncomeCollection()
                .addDocument(from: newIncome)
                .documentID
            
            print("New Income Added : " + documentID)
        } catch {
            print(error)
        }
    }
    
    public func deleteIncome(income: String) async {
        do {
            try await getIncomeCollection()
                .document(income)
                .delete()
        } catch {
            print(error)
        }
    }
    
    public func deleteIncomes() {
        CommonController.delete(collection: UserController().getCurrentUserDocument().collection(ConstantUtils.incomeCollectionName))
    }
    
    public func fetchTotalAmount() async throws -> Double {
        var total = 0.0
        try await withUnsafeThrowingContinuation { continuation in
            getIncomeCollection()
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
    
    func getIncomeList() async throws -> [Income] {
        var incomeList = [Income]()
        incomeList = try await getIncomeCollection()
            .order(by: ConstantUtils.incomeKeyCreditedOn, descending: true)
            .getDocuments()
            .documents
            .map { doc in
                return Income(id: doc.documentID,
                              amount: doc[ConstantUtils.incomeKeyAmount] as? Double ?? 0.0,
                              creditedOn: (doc[ConstantUtils.incomeKeyCreditedOn] as? Timestamp)?.dateValue() ?? Date(),
                              currency: doc[ConstantUtils.incomeKeyCurrency] as? String ?? "",
                              incomeType: doc[ConstantUtils.incomeKeyIncomeType] as? String ?? "")
            }
        return incomeList
    }
    
}

