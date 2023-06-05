//
//  IncomeController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import FirebaseFirestore

// MARK: Income
class IncomeController {
    
    private func getIncomeCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.incomeCollectionName)
    }
    
    public func addIncome(income: Income) async {
        do {
            let documentID = try getIncomeCollection()
                .addDocument(from: income)
                .documentID
            
            print("New Income Added : " + documentID)
            
            await UserController().updateIncomeUserData()
        } catch {
            print(error)
        }
    }
    
    public func deleteIncome(id: String) async {
        do {
            try await getIncomeCollection()
                .document(id)
                .delete()
            
            print("Income Deleted : " + id)
            
            await UserController().updateIncomeUserData()
        } catch {
            print(error)
        }
    }
    
    public func deleteIncomes() {
        CommonController
            .delete(collection: UserController().getCurrentUserDocument().collection(ConstantUtils.incomeCollectionName))
        
        print("All Incomes Deleted.")
    }
    
    private func getIncomeList() async -> [Income] {
        var incomeList = [Income]()
        print("Fetching Income List")
        do {
            incomeList = try await getIncomeCollection()
                .order(by: ConstantUtils.incomeKeyCreditedOn)
                .getDocuments()
                .documents
                .map { doc in
                    return Income(id: doc.documentID,
                                  amount: doc[ConstantUtils.incomeKeyAmount] as? Double ?? 0.0,
                                  taxpaid: doc[ConstantUtils.incomeKeyTaxPaid] as? Double ?? 0.0,
                                  creditedOn: (doc[ConstantUtils.incomeKeyCreditedOn] as? Timestamp)?.dateValue() ?? Date(),
                                  currency: doc[ConstantUtils.incomeKeyCurrency] as? String ?? "",
                                  type: doc[ConstantUtils.incomeKeyIncomeType] as? String ?? "",
                                  tag: doc[ConstantUtils.incomeKeyIncomeTag] as? String ?? "")
                }
            ApplicationData.shared.incomeListUpdatedDate = try await UserController().getCurrentUser().incomeDataUpdatedDate
            ApplicationData.shared.incomeList = incomeList
        } catch {
            print(error)
        }
        print("Income List Fetched")
        return incomeList
    }
    
    public func getIncomeList(incomeType: String = "", incomeTag: String = "", year: String = "", financialYear: String = "") async throws -> [Income] {
        var incomeList = [Income]()
        
        if(await UserController().isNewIncomeAvailable()) {
            print("New")
            incomeList = await getIncomeList()
        } else {
            print("Old")
            incomeList = ApplicationData.shared.incomeList
        }
        
        if(!incomeType.isEmpty) {
            incomeList = incomeList.filter {
                $0.type.elementsEqual(incomeType)
            }
        }
        
        if(!incomeTag.isEmpty) {
            incomeList = incomeList.filter {
                $0.tag.elementsEqual(incomeTag)
            }
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
            
            incomeList = incomeList.filter {
                $0.creditedOn <= Calendar.current.date(from: endDate)! && $0.creditedOn >= Calendar.current.date(from: startDate)!
            }
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
            
            incomeList = incomeList.filter {
                $0.creditedOn <= Calendar.current.date(from: endDate)! && $0.creditedOn >= Calendar.current.date(from: startDate)!
            }
        }
        
        var cumAmount = 0.0
        var cumTaxPaid = 0.0
        incomeList = incomeList.map { value1 in
            var sumAmount = 0.0
            var sumTaxPaid = 0.0
            var totalMonth = 0
            cumAmount = cumAmount + value1.amount
            cumTaxPaid = cumTaxPaid + value1.taxpaid
            incomeList.forEach { value2 in
                if(value1.creditedOn >= value2.creditedOn) {
                    sumAmount += value2.amount
                    sumTaxPaid += value2.taxpaid
                    totalMonth+=1
                }
            }
            return Income(id: value1.id,
                          amount: value1.amount,
                          taxpaid: value1.taxpaid,
                          creditedOn: value1.creditedOn,
                          currency: value1.currency,
                          type: value1.type,
                          tag: value1.tag,
                          avgAmount: sumAmount / Double(totalMonth),
                          avgTaxPaid: sumTaxPaid / Double(totalMonth),
                          cumulativeAmount: cumAmount,
                          cumulativeTaxPaid: cumTaxPaid)
        }.reversed()
        return incomeList
    }
    
    public func fetchTotalAmount(incomeType: String = "", incomeTag: String = "", year: String = "", financialYear: String = "") async throws -> Double {
        let incomeList = try await getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
        
        var total = 0.0
        incomeList.forEach {
            total += $0.amount
        }
        return total
    }
    
    public func fetchTotalTaxPaid(incomeType: String = "", incomeTag: String = "", year: String = "", financialYear: String = "") async throws -> Double {
        let incomeList = try await getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
        
        var total = 0.0
        incomeList.forEach {
            total += $0.taxpaid
        }
        return total
    }
    
    public func getIncomeYearList() async throws -> [String] {
        let incomeList = try await getIncomeList(incomeType: "", incomeTag: "", year: "", financialYear: "")
        
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
    
    public func getIncomeFinancialYearList() async throws -> [String] {
        let incomeList = try await getIncomeList(incomeType: "", incomeTag: "", year: "", financialYear: "")
        
        var returnResponse = [String]()
        if(incomeList.isEmpty) {
            return returnResponse
        }
    
        let firstYear = Calendar.current.dateComponents([.year], from: incomeList.last!.creditedOn).year!
        let lastYear = Calendar.current.dateComponents([.year], from: incomeList.first!.creditedOn).year!
        
        var dateComponent = DateComponents()
        dateComponent.year = firstYear
        dateComponent.month = 1
        dateComponent.day = 1
        let firstDayOfYear = Calendar.current.date(from: dateComponent)!
        
        dateComponent = DateComponents()
        dateComponent.year = firstYear
        dateComponent.month = 3
        dateComponent.day = 31
        let lastDayOfFinancialYear = Calendar.current.date(from: dateComponent)!
        
        let firstFinancialYearAvailable = incomeList.filter {
            firstDayOfYear <= $0.creditedOn && $0.creditedOn <= lastDayOfFinancialYear
        }.count > 0
        
        if(firstFinancialYearAvailable) {
            returnResponse.insert("\(firstYear - 1)-\(firstYear)", at: 0)
        }
        
        var nextYear = firstYear + 1
        var financialYearAvailable = true
        while(financialYearAvailable || nextYear <= (lastYear + 1)) {
            dateComponent = DateComponents()
            dateComponent.year = nextYear - 1
            dateComponent.month = 4
            dateComponent.day = 1
            let firstDayOfFinancialYear = Calendar.current.date(from: dateComponent)!
            
            dateComponent = DateComponents()
            dateComponent.year = nextYear
            dateComponent.month = 3
            dateComponent.day = 31
            let lastDayOfFinancialYear = Calendar.current.date(from: dateComponent)!
            
            financialYearAvailable = incomeList.filter {
                firstDayOfFinancialYear <= $0.creditedOn && $0.creditedOn <= lastDayOfFinancialYear
            }.count > 0
            
            if(financialYearAvailable) {
                returnResponse.insert("\(nextYear - 1)-\(nextYear)", at: 0)
            }
            nextYear = nextYear + 1
        }
        
        return returnResponse
    }
}

// MARK: Income Type
extension IncomeController {
    
    private func getIncomeTypeCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.incomeTypeCollectionName)
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
    
    public func addIncomeType(type: IncomeType) {
        do {
            let documentID = try getIncomeTypeCollection()
                .addDocument(from: type)
                .documentID
            
            print("New Income Type Added : " + documentID)
            
            if(type.isdefault) {
                makeOtherIncomeTypeNonDefault(documentID: documentID)
            }
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
            addIncomeType(type: incomeType)
        }
    }
    
    public func updateIncomeType(type: IncomeType) {
        do {
            try getIncomeTypeCollection()
                .document(type.id!)
                .setData(from: type, merge: true)
            
            print("Income Type : " + type.id! + " Updated")
        } catch {
            print(error)
        }
    }
    
    public func deleteIncomeTypes() {
        CommonController.delete(collection: UserController().getCurrentUserDocument().collection(ConstantUtils.incomeTypeCollectionName))
    }
    
}

// MARK: Income Tag
extension IncomeController {
    
    private func getIncomeTagCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.incomeTagCollectionName)
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
            
            if(tag.isdefault) {
                makeOtherIncomeTagNonDefault(documentID: documentID)
            }
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
            
            print("Income Tag : " + tag.id! + " Updated")
        } catch {
            print(error)
        }
    }
    
    public func deleteIncomeTags() {
        CommonController.delete(collection: UserController().getCurrentUserDocument().collection(ConstantUtils.incomeTagCollectionName))
    }
    
}
