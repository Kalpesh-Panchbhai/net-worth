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
    
    private func getIncomeTagCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.incomeTagCollectionName)
    }
    
    private func getIncomeTypeCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.incomeTypeCollectionName)
    }
    
    public func addIncome(incometype: IncomeType, amount: String, date: Date, currency: String, tag: IncomeTag) async {
        let newIncome = Income(amount: Double(amount) ?? 0.0, creditedOn: date, currency: currency, incomeType: incometype.name, tag: tag.name)
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
                              incomeType: doc[ConstantUtils.incomeKeyIncomeType] as? String ?? "",
                              tag: doc[ConstantUtils.incomeKeyIncomeTag] as? String ?? "")
            }
        return incomeList
    }
    
    func getIncomeTagList() async throws -> [IncomeTag] {
        var incomeTagList = [IncomeTag]()
        incomeTagList = try await getIncomeTagCollection()
            .order(by: ConstantUtils.incomeTagKeyName)
            .getDocuments()
            .documents
            .map { doc in
                return IncomeTag(id: doc.documentID,
                                 name: doc[ConstantUtils.incomeTagKeyName] as? String ?? "")
            }
        
        return incomeTagList
    }
    
    public func addIncomeTag(tag: IncomeTag) async {
        do {
            let documentID = try getIncomeTagCollection()
                .addDocument(from: tag)
                .documentID
            
            print("New Income Tag Added : " + documentID)
        } catch {
            print(error)
        }
    }
    
    func getIncomeTypeList() async throws -> [IncomeType] {
        var incomeTypeList = [IncomeType]()
        incomeTypeList = try await getIncomeTypeCollection()
            .order(by: ConstantUtils.incomeTypeKeyName)
            .getDocuments()
            .documents
            .map { doc in
                return IncomeType(id: doc.documentID,
                                 name: doc[ConstantUtils.incomeTypeKeyName] as? String ?? "")
            }
        
        return incomeTypeList
    }
    
    public func addIncomeType(tag: IncomeType) async {
        do {
            let documentID = try getIncomeTypeCollection()
                .addDocument(from: tag)
                .documentID
            
            print("New Income Type Added : " + documentID)
        } catch {
            print(error)
        }
    }
}

