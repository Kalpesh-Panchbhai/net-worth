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
    
    private func getIncomeList() async -> [Income] {
        var incomeList = [Income]()
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
            ApplicationData.shared.incomeListUpdatedDate = await UserController().getCurrentUser().incomeDataUpdatedDate
            ApplicationData.shared.incomeList = incomeList
        } catch {
            print(error)
        }
        return incomeList
    }
    
    public func getIncomeList(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String]()) async -> [IncomeCalculation] {
        var incomeList = [Income]()
        
        if(await UserController().isNewIncomeAvailable()) {
            incomeList = await getIncomeList()
        } else {
            incomeList = ApplicationData.shared.incomeList
        }
        
        if(!incomeType.isEmpty) {
            incomeList = incomeList.filter {
                incomeType.contains($0.type)
            }
        }
        
        if(!incomeTag.isEmpty) {
            incomeList = incomeList.filter {
                incomeTag.contains($0.tag)
            }
        }
        
        if(!year.isEmpty) {
            var filterIncomeList = [Income]()
            for y in year {
                let calendar = Calendar.current
                let startDate = DateComponents(
                    calendar: calendar,
                    year: y.integer,
                    month: 1,
                    day: 1,
                    hour: 0,
                    minute: 0,
                    second: 0)
                
                let endDate = DateComponents(
                    calendar: calendar,
                    year: y.integer,
                    month: 12,
                    day: 31,
                    hour: 23,
                    minute: 59,
                    second: 59)
                filterIncomeList.append(contentsOf: incomeList.filter {
                    $0.creditedOn <= Calendar.current.date(from: endDate)! && $0.creditedOn >= Calendar.current.date(from: startDate)!
                })
            }
            incomeList = filterIncomeList.sorted(by: {$0.creditedOn < $1.creditedOn})
        }
        
        if(!financialYear.isEmpty) {
            var filterIncomeList = [Income]()
            for fy in financialYear {
                let financialYears = fy.split(separator: "-")
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
                filterIncomeList.append(contentsOf: incomeList.filter {
                    $0.creditedOn <= Calendar.current.date(from: endDate)! && $0.creditedOn >= Calendar.current.date(from: startDate)!
                })
            }
            incomeList = filterIncomeList.sorted(by: {$0.creditedOn < $1.creditedOn})
        }
        
        var cumAmount = 0.0
        var cumTaxPaid = 0.0
        let returnIncomeList = incomeList.map { value1 in
            var sumAmount = 0.0
            var sumTaxPaid = 0.0
            var totalMonth = 0.0
            var totalDays = 0
            var maxDays = 0
            cumAmount = cumAmount + value1.amount
            cumTaxPaid = cumTaxPaid + value1.taxpaid
            incomeList.forEach { value2 in
                if(value1.creditedOn >= value2.creditedOn) {
                    sumAmount += value2.amount
                    sumTaxPaid += value2.taxpaid
                    totalDays = value1.creditedOn.removeTimeStamp().days(from: value2.creditedOn.removeTimeStamp())
                    maxDays = maxDays < totalDays ? totalDays : maxDays
                }
            }
            maxDays+=30
            totalMonth = Double(maxDays) / Double(30)
            return IncomeCalculation(id: value1.id,
                                     amount: value1.amount,
                                     taxpaid: value1.taxpaid,
                                     creditedOn: value1.creditedOn,
                                     currency: value1.currency,
                                     type: value1.type,
                                     tag: value1.tag,
                                     avgAmount: sumAmount / totalMonth,
                                     avgTaxPaid: sumTaxPaid / totalMonth,
                                     cumulativeAmount: cumAmount,
                                     cumulativeTaxPaid: cumTaxPaid)
        }
        return returnIncomeList.reversed()
    }
    
    public func fetchTotalAmount(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String]()) async -> Double {
        let incomeList = await getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
        
        var total = 0.0
        incomeList.forEach {
            total += $0.amount
        }
        return total
    }
    
    public func fetchTotalTaxPaid(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String]()) async -> Double {
        let incomeList = await getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
        
        var total = 0.0
        incomeList.forEach {
            total += $0.taxpaid
        }
        return total
    }
    
    public func getIncomeYearList() async -> [String] {
        let incomeList = await getIncomeList(incomeType: [String](), incomeTag: [String](), year: [String](), financialYear: [String]())
        
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
    
    public func getIncomeFinancialYearList() async -> [String] {
        let incomeList = await getIncomeList(incomeType: [String](), incomeTag: [String](), year: [String](), financialYear: [String]())
        
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
    
    public func groupByType(list: [IncomeCalculation]) -> [String: [IncomeCalculation]] {
        let groupByType = Dictionary(grouping: list, by: {$0.type})
        var incomeListByGroupUpdated = [String: [IncomeCalculation]]()
        
        for (key, value) in groupByType {
            var cumAmount = 0.0
            var cumTaxPaid = 0.0
            let returnIncomeList = value.reversed().map { value1 in
                var sumAmount = 0.0
                var sumTaxPaid = 0.0
                var totalMonth = 0.0
                var totalDays = 0
                var maxDays = 0
                cumAmount = cumAmount + value1.amount
                cumTaxPaid = cumTaxPaid + value1.taxpaid
                value.reversed().forEach { value2 in
                    if(value1.creditedOn >= value2.creditedOn) {
                        sumAmount += value2.amount
                        sumTaxPaid += value2.taxpaid
                        totalDays = value1.creditedOn.removeTimeStamp().days(from: value2.creditedOn.removeTimeStamp())
                        maxDays = maxDays < totalDays ? totalDays : maxDays
                    }
                }
                maxDays+=30
                totalMonth = Double(maxDays) / Double(30)
                return IncomeCalculation(id: value1.id,
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
            }
            
            incomeListByGroupUpdated.updateValue(returnIncomeList.reversed(), forKey: key)
        }
        
        return incomeListByGroupUpdated
    }
    
    public func groupByTag(list: [IncomeCalculation]) -> [String: [IncomeCalculation]] {
        let groupByTag = Dictionary(grouping: list, by: {$0.tag})
        var incomeListByGroupUpdated = [String: [IncomeCalculation]]()
        
        for (key, value) in groupByTag {
            var cumAmount = 0.0
            var cumTaxPaid = 0.0
            let returnIncomeList = value.reversed().map { value1 in
                var sumAmount = 0.0
                var sumTaxPaid = 0.0
                var totalMonth = 0.0
                var totalDays = 0
                var maxDays = 0
                cumAmount = cumAmount + value1.amount
                cumTaxPaid = cumTaxPaid + value1.taxpaid
                value.reversed().forEach { value2 in
                    if(value1.creditedOn >= value2.creditedOn) {
                        sumAmount += value2.amount
                        sumTaxPaid += value2.taxpaid
                        totalDays = value1.creditedOn.removeTimeStamp().days(from: value2.creditedOn.removeTimeStamp())
                        maxDays = maxDays < totalDays ? totalDays : maxDays
                    }
                }
                maxDays+=30
                totalMonth = Double(maxDays) / Double(30)
                return IncomeCalculation(id: value1.id,
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
            }
            
            incomeListByGroupUpdated.updateValue(returnIncomeList.reversed(), forKey: key)
        }
        
        return incomeListByGroupUpdated
    }
    
    public func groupByYear(list: [IncomeCalculation]) -> [String: [IncomeCalculation]] {
        let groupByYear = Dictionary(grouping: list) { (income) -> String in
            let date = Calendar.current.dateComponents([.year], from: income.creditedOn)
            
            return String(date.year ?? 0)
            
        }
        var incomeListByGroupUpdated = [String: [IncomeCalculation]]()
        
        for (key, value) in groupByYear {
            var cumAmount = 0.0
            var cumTaxPaid = 0.0
            let returnIncomeList = value.reversed().map { value1 in
                var sumAmount = 0.0
                var sumTaxPaid = 0.0
                var totalMonth = 0.0
                var totalDays = 0
                var maxDays = 0
                cumAmount = cumAmount + value1.amount
                cumTaxPaid = cumTaxPaid + value1.taxpaid
                value.reversed().forEach { value2 in
                    if(value1.creditedOn >= value2.creditedOn) {
                        sumAmount += value2.amount
                        sumTaxPaid += value2.taxpaid
                        totalDays = value1.creditedOn.removeTimeStamp().days(from: value2.creditedOn.removeTimeStamp())
                        maxDays = maxDays < totalDays ? totalDays : maxDays
                    }
                }
                maxDays+=30
                totalMonth = Double(maxDays) / Double(30)
                return IncomeCalculation(id: value1.id,
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
            }
            
            incomeListByGroupUpdated.updateValue(returnIncomeList.reversed(), forKey: key)
        }
        
        return incomeListByGroupUpdated
    }
    
    public func groupByFinancialYear(list: [IncomeCalculation]) -> [String: [IncomeCalculation]] {
        var financialYearList = [String]()
        
        let firstYear = Calendar.current.dateComponents([.year], from: list.last!.creditedOn).year!
        let lastYear = Calendar.current.dateComponents([.year], from: list.first!.creditedOn).year!
        
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
        
        let firstFinancialYearAvailable = list.filter {
            firstDayOfYear <= $0.creditedOn && $0.creditedOn <= lastDayOfFinancialYear
        }.count > 0
        
        if(firstFinancialYearAvailable) {
            financialYearList.insert("\(firstYear - 1)-\(firstYear)", at: 0)
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
            
            financialYearAvailable = list.filter {
                firstDayOfFinancialYear <= $0.creditedOn && $0.creditedOn <= lastDayOfFinancialYear
            }.count > 0
            
            if(financialYearAvailable) {
                financialYearList.insert("\(nextYear - 1)-\(nextYear)", at: 0)
            }
            nextYear = nextYear + 1
        }
        
        var incomeListByGroupUpdated = [String: [IncomeCalculation]]()
        
        if(!financialYearList.isEmpty) {
            for financialYear in financialYearList {
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
                
                let filterList = list.filter {
                    $0.creditedOn <= Calendar.current.date(from: endDate)! && $0.creditedOn >= Calendar.current.date(from: startDate)!
                }
                
                var cumAmount = 0.0
                var cumTaxPaid = 0.0
                let returnIncomeList = filterList.reversed().map { value1 in
                    var sumAmount = 0.0
                    var sumTaxPaid = 0.0
                    var totalMonth = 0.0
                    var totalDays = 0
                    var maxDays = 0
                    cumAmount = cumAmount + value1.amount
                    cumTaxPaid = cumTaxPaid + value1.taxpaid
                    filterList.reversed().forEach { value2 in
                        if(value1.creditedOn >= value2.creditedOn) {
                            sumAmount += value2.amount
                            sumTaxPaid += value2.taxpaid
                            totalDays = value1.creditedOn.removeTimeStamp().days(from: value2.creditedOn.removeTimeStamp())
                            maxDays = maxDays < totalDays ? totalDays : maxDays
                        }
                    }
                    maxDays+=30
                    totalMonth = Double(maxDays) / Double(30)
                    return IncomeCalculation(id: value1.id,
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
                }
                incomeListByGroupUpdated.updateValue(returnIncomeList.reversed(), forKey: financialYear)
            }
        }
        return incomeListByGroupUpdated
    }
}
