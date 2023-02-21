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
    
    public func addIncome(type: IncomeType, amount: String, date: Date, currency: String, tag: IncomeTag) async {
        let newIncome = Income(amount: Double(amount) ?? 0.0, creditedOn: date, currency: currency, type: type.name, tag: tag.name)
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
                              type: doc[ConstantUtils.incomeKeyIncomeType] as? String ?? "",
                              tag: doc[ConstantUtils.incomeKeyIncomeTag] as? String ?? "")
            }
        return incomeList
    }
    
    func getIncomeList(incomeType: String, incomeTag: String, year: String, financialYear: String) async throws -> [Income] {
        var incomeList = [Income]()
        
        var query = getIncomeCollection()
            .order(by: ConstantUtils.incomeKeyCreditedOn, descending: true)
        
        if(!incomeType.isEmpty) {
            query = query
                .whereField(ConstantUtils.incomeKeyIncomeType, isEqualTo: incomeType)
        }
        
        if(!incomeTag.isEmpty) {
            query = query
                .whereField(ConstantUtils.incomeKeyIncomeTag, isEqualTo: incomeTag)
        }
        
        if(!year.isEmpty) {
            let calendar = Calendar.current
            let startDate = DateComponents(
                calendar: calendar,
                year: year.integer,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                second: 0)
            
            let endDate = DateComponents(
                calendar: calendar,
                year: year.integer,
                month: 12,
                day: 31,
                hour: 23,
                minute: 59,
                second: 59)
            
            query = query
                .whereField(ConstantUtils.incomeKeyCreditedOn, isLessThanOrEqualTo: Timestamp.init(date: endDate.date ?? Date()))
                .whereField(ConstantUtils.incomeKeyCreditedOn, isGreaterThanOrEqualTo: Timestamp.init(date: startDate.date ?? Date()))
        }
        
        if(!financialYear.isEmpty) {
            let financialYears = financialYear.split(separator: "-")
            let calendar = Calendar.current
            let startDate = DateComponents(
                calendar: calendar,
                year: financialYears[0].integer,
                month: 4,
                day: 1,
                hour: 0,
                minute: 0,
                second: 0)
            
            let endDate = DateComponents(
                calendar: calendar,
                year: financialYears[1].integer,
                month: 3,
                day: 31,
                hour: 23,
                minute: 59,
                second: 59)
            
            query = query
                .whereField(ConstantUtils.incomeKeyCreditedOn, isLessThanOrEqualTo: Timestamp.init(date: endDate.date ?? Date()))
                .whereField(ConstantUtils.incomeKeyCreditedOn, isGreaterThanOrEqualTo: Timestamp.init(date: startDate.date ?? Date()))
        }
        
        incomeList = try await query
            .getDocuments()
            .documents
            .map { doc in
                return Income(id: doc.documentID,
                              amount: doc[ConstantUtils.incomeKeyAmount] as? Double ?? 0.0,
                              creditedOn: (doc[ConstantUtils.incomeKeyCreditedOn] as? Timestamp)?.dateValue() ?? Date(),
                              currency: doc[ConstantUtils.incomeKeyCurrency] as? String ?? "",
                              type: doc[ConstantUtils.incomeKeyIncomeType] as? String ?? "",
                              tag: doc[ConstantUtils.incomeKeyIncomeTag] as? String ?? "")
            }
        return incomeList
    }
    
    public func fetchTotalAmount(incomeType: String, incomeTag: String, year: String, financialYear: String) async throws -> Double {
        var total = 0.0
        try await withUnsafeThrowingContinuation { continuation in
            var query = getIncomeCollection()
                .order(by: ConstantUtils.incomeKeyCreditedOn, descending: true)
            
            if(!incomeType.isEmpty) {
                query = query
                    .whereField(ConstantUtils.incomeKeyIncomeType, isEqualTo: incomeType)
            }
            
            if(!incomeTag.isEmpty) {
                query = query
                    .whereField(ConstantUtils.incomeKeyIncomeTag, isEqualTo: incomeTag)
            }
            
            if(!year.isEmpty) {
                let calendar = Calendar.current
                let startDate = DateComponents(
                    calendar: calendar,
                    year: year.integer,
                    month: 1,
                    day: 1,
                    hour: 0,
                    minute: 0,
                    second: 0)
                
                let endDate = DateComponents(
                    calendar: calendar,
                    year: year.integer,
                    month: 12,
                    day: 31,
                    hour: 23,
                    minute: 59,
                    second: 59)
                
                query = query
                    .whereField(ConstantUtils.incomeKeyCreditedOn, isLessThanOrEqualTo: Timestamp.init(date: endDate.date ?? Date()))
                    .whereField(ConstantUtils.incomeKeyCreditedOn, isGreaterThanOrEqualTo: Timestamp.init(date: startDate.date ?? Date()))
            }
            
            if(!financialYear.isEmpty) {
                let financialYears = financialYear.split(separator: "-")
                let calendar = Calendar.current
                let startDate = DateComponents(
                    calendar: calendar,
                    year: financialYears[0].integer,
                    month: 4,
                    day: 1,
                    hour: 0,
                    minute: 0,
                    second: 0)
                
                let endDate = DateComponents(
                    calendar: calendar,
                    year: financialYears[1].integer,
                    month: 3,
                    day: 31,
                    hour: 23,
                    minute: 59,
                    second: 59)
                
                query = query
                    .whereField(ConstantUtils.incomeKeyCreditedOn, isLessThanOrEqualTo: Timestamp.init(date: endDate.date ?? Date()))
                    .whereField(ConstantUtils.incomeKeyCreditedOn, isGreaterThanOrEqualTo: Timestamp.init(date: startDate.date ?? Date()))
            }
            
            query.getDocuments { snapshot, error in
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
    
    func getIncomeTagList() async throws -> [IncomeTag] {
        var incomeTagList = [IncomeTag]()
        incomeTagList = try await getIncomeTagCollection()
            .order(by: ConstantUtils.incomeTagKeyName)
            .getDocuments()
            .documents
            .map { doc in
                return IncomeTag(id: doc.documentID,
                                 name: doc[ConstantUtils.incomeTagKeyName] as? String ?? "",
                                 isdefault: doc[ConstantUtils.incomeTagKeyIsDefault] as? Bool ?? false)
            }
        
        return incomeTagList
    }
    
    public func addIncomeTag(tag: IncomeTag) {
        do {
            let documentID = try getIncomeTagCollection()
                .addDocument(from: tag)
                .documentID
            
            print("New Income Tag Added : " + documentID)
            
            makeOtherIncomeTagNonDefault(documentID: documentID)
        } catch {
            print(error)
        }
    }
    
    public func makeOtherIncomeTagNonDefault(documentID: String) {
        getIncomeTagCollection()
            .getDocuments { snapshot, error in
                if error  == nil {
                    if let snapshot = snapshot {
                        snapshot.documents.forEach { doc in
                            if(!doc.documentID.elementsEqual(documentID) && (doc[ConstantUtils.incomeTagKeyIsDefault] as? Bool ?? false)) {
                                let updatedIncomeTag = IncomeTag(id: doc.documentID,
                                                                 name: doc[ConstantUtils.incomeTagKeyName] as? String ?? "",
                                                                 isdefault: false)
                                self.updateIncomeTag(tag: updatedIncomeTag)
                            }
                        }
                    }
                }
            }
    }
    
    public func addDefaultIncomeTag() async throws {
        let count = try await getIncomeTagList().count
        if(count == 0) {
            let incomeTag = IncomeTag(name: "None", isdefault: false)
            addIncomeTag(tag: incomeTag)
        }
    }
    
    public func updateIncomeTag(tag: IncomeTag) {
        do {
            try getIncomeTagCollection()
                .document(tag.id!)
                .setData(from: tag, merge: true)
        } catch {
            print(error)
        }
    }
    
    public func deleteIncomeTags() {
        CommonController.delete(collection: UserController().getCurrentUserDocument().collection(ConstantUtils.incomeTagCollectionName))
    }
    
    func getIncomeTypeList() async throws -> [IncomeType] {
        var incomeTypeList = [IncomeType]()
        incomeTypeList = try await getIncomeTypeCollection()
            .order(by: ConstantUtils.incomeTypeKeyName)
            .getDocuments()
            .documents
            .map { doc in
                return IncomeType(id: doc.documentID,
                                  name: doc[ConstantUtils.incomeTypeKeyName] as? String ?? "",
                                  isdefault: doc[ConstantUtils.incomeTagKeyIsDefault] as? Bool ?? false)
            }
        
        return incomeTypeList
    }
    
    public func addIncomeType(tag: IncomeType) {
        do {
            let documentID = try getIncomeTypeCollection()
                .addDocument(from: tag)
                .documentID
            
            print("New Income Type Added : " + documentID)
            
            makeOtherIncomeTypeNonDefault(documentID: documentID)
        } catch {
            print(error)
        }
    }
    
    public func makeOtherIncomeTypeNonDefault(documentID: String) {
        getIncomeTypeCollection()
            .getDocuments { snapshot, error in
                if error  == nil {
                    if let snapshot = snapshot {
                        snapshot.documents.forEach { doc in
                            if(!doc.documentID.elementsEqual(documentID) && (doc[ConstantUtils.incomeTypeKeyIsDefault] as? Bool ?? false)) {
                                let updatedIncomeType = IncomeType(id: doc.documentID,
                                                                   name: doc[ConstantUtils.incomeTypeKeyName] as? String ?? "",
                                                                   isdefault: false)
                                self.updateIncomeType(type: updatedIncomeType)
                            }
                        }
                    }
                }
            }
    }
    
    public func addDefaultIncomeType() async throws {
        let count = try await getIncomeTypeList().count
        if(count == 0) {
            let incomeType = IncomeType(name: "None", isdefault: false)
            addIncomeType(tag: incomeType)
        }
    }
    
    public func updateIncomeType(type: IncomeType) {
        do {
            try getIncomeTypeCollection()
                .document(type.id!)
                .setData(from: type, merge: true)
        } catch {
            print(error)
        }
    }
    
    public func deleteIncomeTypes() {
        CommonController.delete(collection: UserController().getCurrentUserDocument().collection(ConstantUtils.incomeTypeCollectionName))
    }
    
    func getIncomeYearList() async throws -> [String] {
        var incomeList = [Income]()
        incomeList = try await getIncomeList()
        
        let grouped = Dictionary(grouping: incomeList) { (income) -> Int in
            let date = Calendar.current.dateComponents([.year], from: income.creditedOn)
            
            return date.year ?? 0
            
        }
        return grouped.map({
            $0.key
        }).sorted(by: {
            $0 > $1
        }).map { value in
            return String(value).replacingOccurrences(of: ",", with: "")
        }
        
    }
}

