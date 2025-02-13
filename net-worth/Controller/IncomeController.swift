//
//  IncomeController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//
import Foundation

class IncomeController {
    
    private var restController = RestController()
    private var entityName = ConstantUtils.Entity.INCOME.rawValue
    
    public func getIncomeList() async -> [IncomeRestModel] {
        let userId = ApplicationData.shared.userId
        let response = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.GET.rawValue, pathParam: userId, forClass: [IncomeRestModel].self)
        return response.sorted(by: {
            return $0.creditedDate < $1.creditedDate
        })
    }
    
    public func addIncome(income: IncomeRestModel) async {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(income)
        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.POST.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func updateIncome(income: IncomeRestModel) async {
//        let userId = ApplicationData.shared.userId
//        let requestData = IncomeRestModel(id: income.id, userId: userId, amount: income.amount, taxPaid: income.taxpaid, creditedOn: income.creditedOn.localToUTCString(), currency: income.currency, incomeType: income.type, incomeTag: income.tag)
//        let encoder = JSONEncoder()
//        let data = try! encoder.encode(requestData)
//        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.PATCH.rawValue, body: data, forClass: RestResponse.self)
    }
    
    public func deleteIncome(income: IncomeRestModel) async {
//        _ = await restController.executeAPI(entity: entityName, httpMethod: ConstantUtils.HTTP_METHOD.DELETE.rawValue, pathParam: income.id, forClass: RestResponse.self)
    }
    
    public func getIncomeList(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String](), incomeList: [IncomeRestModel]) async -> [IncomeRestModel] {
        var incomeList = incomeList
        
//        if(!incomeType.isEmpty) {
//            incomeList = incomeList.filter {
//                incomeType.contains($0.incomeType)
//            }
//        }
//        
//        if(!incomeTag.isEmpty) {
//            incomeList = incomeList.filter {
//                incomeTag.contains($0.incomeTag)
//            }
//        }
//        
//        if(!year.isEmpty) {
//            var filterIncomeList = [IncomeRestModel]()
//            for y in year {
//                let calendar = Calendar.current
//                let startDate = DateComponents(
//                    calendar: calendar,
//                    year: y.integer,
//                    month: 1,
//                    day: 1,
//                    hour: 0,
//                    minute: 0,
//                    second: 0)
//                
//                let endDate = DateComponents(
//                    calendar: calendar,
//                    year: y.integer,
//                    month: 12,
//                    day: 31,
//                    hour: 23,
//                    minute: 59,
//                    second: 59)
//                filterIncomeList.append(contentsOf: incomeList.filter {
//                    $0.creditedDate <= Calendar.current.date(from: endDate)! && $0.creditedOn >= Calendar.current.date(from: startDate)!
//                })
//            }
//            incomeList = filterIncomeList.sorted(by: {$0.creditedDate < $1.creditedDate})
//        }
//        
//        if(!financialYear.isEmpty) {
//            var filterIncomeList = [IncomeRestModel]()
//            for fy in financialYear {
//                let financialYears = fy.split(separator: "-")
//                let calendar = Calendar.current
//                let startDate = DateComponents(
//                    calendar: calendar,
//                    year: financialYears[0].integer,
//                    month: 4,
//                    day: 1,
//                    hour: 0,
//                    minute: 0,
//                    second: 0)
//                
//                let endDate = DateComponents(
//                    calendar: calendar,
//                    year: financialYears[1].integer,
//                    month: 3,
//                    day: 31,
//                    hour: 23,
//                    minute: 59,
//                    second: 59)
//                filterIncomeList.append(contentsOf: incomeList.filter {
//                    $0.creditedDate <= Calendar.current.date(from: endDate)! && $0.creditedDate >= Calendar.current.date(from: startDate)!
//                })
//            }
//            incomeList = filterIncomeList.sorted(by: {$0.creditedDate < $1.creditedDate})
//        }
//        
//        var cumAmount = 0.0
//        var cumTaxPaid = 0.0
//        let returnIncomeList = incomeList.map { value1 in
//            var sumAmount = 0.0
//            var sumTaxPaid = 0.0
//            var totalMonth = 0.0
//            var totalDays = 0
//            var maxDays = 0
//            cumAmount = cumAmount + value1.amount
//            cumTaxPaid = cumTaxPaid + value1.taxPaid
//            incomeList.forEach { value2 in
//                if(value1.creditedDate >= value2.creditedDate) {
//                    sumAmount += value2.amount
//                    sumTaxPaid += value2.taxPaid
//                    
//                    let date = DateComponents(
//                        calendar: Calendar.current,
//                        year: value2.creditedDate.getDateComponents().year,
//                        month: value2.creditedDate.getDateComponents().month,
//                        day: 1)
//                    totalDays = value1.creditedDate.removeTimeStamp().days(from: Calendar.current.date(from: date)!) + 1
//                    maxDays = maxDays < totalDays ? totalDays : maxDays
//                }
//            }
//            totalMonth = Double(maxDays) / Double(30)
//            return IncomeRestModel(id: value1.id,
//                                     amount: value1.amount,
//                                     taxpaid: value1.taxPaid,
//                                     creditedOn: value1.creditedDate,
//                                     currency: value1.currency,
//                                     type: value1.incomeType,
//                                     tag: value1.incomeTag,
//                                     avgAmount: sumAmount / totalMonth,
//                                     avgTaxPaid: sumTaxPaid / totalMonth,
//                                     cumulativeAmount: cumAmount,
//                                     cumulativeTaxPaid: cumTaxPaid)
//        }
//        return returnIncomeList.reversed()
        return incomeList;
    }
    
    public func fetchTotal(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String](), field: String, income: [IncomeRestModel]) async -> Double {
        let incomeList = await getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear, incomeList: income)
        
        var total = 0.0
        incomeList.forEach {
            if(field.elementsEqual("Amount")) {
                total += $0.amount
            } else if(field.elementsEqual("Tax")) {
                total += $0.taxPaid
            }
        }
        return total
    }
    
    public func getIncomeYearList(income: [IncomeRestModel]) async -> [String] {
        let incomeList = await getIncomeList(incomeType: [String](), incomeTag: [String](), year: [String](), financialYear: [String](), incomeList: income)
  
        return []
//        let grouped = Dictionary(grouping: incomeList) { (income) -> Int in
//            let date = Calendar.current.dateComponents([.year], from: income.creditedDate)
//            
//            return date.year ?? 0
//            
//        }
//        return grouped.map({
//            $0.key
//        }).sorted(by: {
//            $0 > $1
//        }).map { value in
//            return String(value).replacingOccurrences(of: ",", with: "")
//        }
    }
    
    public func getIncomeFinancialYearList(income: [IncomeRestModel]) async -> [String] {
        let incomeList = await getIncomeList(incomeType: [String](), incomeTag: [String](), year: [String](), financialYear: [String](), incomeList: income)
        
        var returnResponse = [String]()
//        if(incomeList.isEmpty) {
//            return returnResponse
//        }
//        
//        let firstYear = Calendar.current.dateComponents([.year], from: incomeList.last!.creditedDate).year!
//        let lastYear = Calendar.current.dateComponents([.year], from: incomeList.first!.creditedDate).year!
//        
//        var dateComponent = DateComponents()
//        dateComponent.year = firstYear
//        dateComponent.month = 1
//        dateComponent.day = 1
//        let firstDayOfYear = Calendar.current.date(from: dateComponent)!
//        
//        dateComponent = DateComponents()
//        dateComponent.year = firstYear
//        dateComponent.month = 3
//        dateComponent.day = 31
//        let lastDayOfFinancialYear = Calendar.current.date(from: dateComponent)!
//        
//        let firstFinancialYearAvailable = incomeList.filter {
//            firstDayOfYear <= $0.creditedDate && $0.creditedDate <= lastDayOfFinancialYear
//        }.count > 0
//        
//        if(firstFinancialYearAvailable) {
//            returnResponse.insert("\(firstYear - 1)-\(firstYear)", at: 0)
//        }
//        
//        var nextYear = firstYear + 1
//        var financialYearAvailable = true
//        while(financialYearAvailable || nextYear <= (lastYear + 1)) {
//            dateComponent = DateComponents()
//            dateComponent.year = nextYear - 1
//            dateComponent.month = 4
//            dateComponent.day = 1
//            let firstDayOfFinancialYear = Calendar.current.date(from: dateComponent)!
//            
//            dateComponent = DateComponents()
//            dateComponent.year = nextYear
//            dateComponent.month = 3
//            dateComponent.day = 31
//            let lastDayOfFinancialYear = Calendar.current.date(from: dateComponent)!
//            
//            financialYearAvailable = incomeList.filter {
//                firstDayOfFinancialYear <= $0.creditedDate && $0.creditedDate <= lastDayOfFinancialYear
//            }.count > 0
//            
//            if(financialYearAvailable) {
//                returnResponse.insert("\(nextYear - 1)-\(nextYear)", at: 0)
//            }
//            nextYear = nextYear + 1
//        }
        
        return returnResponse
    }
    
    public func incomeListGroupBy(list: [IncomeRestModel], groupBy: String) -> [String: [IncomeRestModel]] {
        var groupByIncomeList = [String: [IncomeRestModel]]()
        var returnGroupByIncomeList = [String: [IncomeRestModel]]()
//        if(groupBy.elementsEqual("Type")) {
//            groupByIncomeList = Dictionary(grouping: list, by: {$0.incomeType})
//        } else if(groupBy.elementsEqual("Tag")) {
//            groupByIncomeList = Dictionary(grouping: list, by: {$0.incomeTag})
//        } else if(groupBy.elementsEqual("Year")) {
//            groupByIncomeList = Dictionary(grouping: list) { (income) -> String in
//                let date = Calendar.current.dateComponents([.year], from: income.creditedDate)
//                return String(date.year ?? 0)
//            }
//        } else if(groupBy.elementsEqual("Financial Year")) {
//            return incomeListGroupByFinancialYear(list: list)
//        }
//        
//        for (key, value) in groupByIncomeList {
//            var cumAmount = 0.0
//            var cumTaxPaid = 0.0
//            let returnIncomeList = value.reversed().map { value1 in
//                var sumAmount = 0.0
//                var sumTaxPaid = 0.0
//                var totalMonth = 0.0
//                var totalDays = 0
//                var maxDays = 0
//                cumAmount = cumAmount + value1.amount
//                cumTaxPaid = cumTaxPaid + value1.taxPaid
//                value.reversed().forEach { value2 in
//                    if(value1.creditedDate >= value2.creditedDate) {
//                        sumAmount += value2.amount
//                        sumTaxPaid += value2.taxPaid
//                        
//                        let date = DateComponents(
//                            calendar: Calendar.current,
//                            year: value2.creditedDate.getDateComponents().year,
//                            month: value2.creditedDate.getDateComponents().month,
//                            day: 1)
//                        totalDays = value1.creditedDate.removeTimeStamp().days(from: Calendar.current.date(from: date)!) + 1
//                        maxDays = maxDays < totalDays ? totalDays : maxDays
//                    }
//                }
//                totalMonth = Double(maxDays) / Double(30)
//                return IncomeRestModel(id: value1.id,
//                                         amount: value1.amount,
//                                         taxpaid: value1.taxPaid,
//                                         creditedOn: value1.creditedDate,
//                                         currency: value1.currency,
//                                         type: value1.type,
//                                         tag: value1.tag,
//                                         avgAmount: sumAmount / Double(totalMonth),
//                                         avgTaxPaid: sumTaxPaid / Double(totalMonth),
//                                         cumulativeAmount: cumAmount,
//                                         cumulativeTaxPaid: cumTaxPaid)
//            }
//            
//            returnGroupByIncomeList.updateValue(returnIncomeList.reversed(), forKey: key)
//        }
        
        return returnGroupByIncomeList
    }
    
    private func incomeListGroupByFinancialYear(list: [IncomeRestModel]) -> [String: [IncomeRestModel]] {
//        var financialYearList = [String]()
//        
//        let firstYear = Calendar.current.dateComponents([.year], from: list.last!.creditedDate).year!
//        let lastYear = Calendar.current.dateComponents([.year], from: list.first!.creditedDate).year!
//        
//        var dateComponent = DateComponents()
//        dateComponent.year = firstYear
//        dateComponent.month = 1
//        dateComponent.day = 1
//        let firstDayOfYear = Calendar.current.date(from: dateComponent)!
//        
//        dateComponent = DateComponents()
//        dateComponent.year = firstYear
//        dateComponent.month = 3
//        dateComponent.day = 31
//        let lastDayOfFinancialYear = Calendar.current.date(from: dateComponent)!
//        
//        let firstFinancialYearAvailable = list.filter {
//            firstDayOfYear <= $0.creditedDate && $0.creditedDate <= lastDayOfFinancialYear
//        }.count > 0
//        
//        if(firstFinancialYearAvailable) {
//            financialYearList.insert("\(firstYear - 1)-\(firstYear)", at: 0)
//        }
//        
//        var nextYear = firstYear + 1
//        var financialYearAvailable = true
//        while(financialYearAvailable || nextYear <= (lastYear + 1)) {
//            dateComponent = DateComponents()
//            dateComponent.year = nextYear - 1
//            dateComponent.month = 4
//            dateComponent.day = 1
//            let firstDayOfFinancialYear = Calendar.current.date(from: dateComponent)!
//            
//            dateComponent = DateComponents()
//            dateComponent.year = nextYear
//            dateComponent.month = 3
//            dateComponent.day = 31
//            let lastDayOfFinancialYear = Calendar.current.date(from: dateComponent)!
//            
//            financialYearAvailable = list.filter {
//                firstDayOfFinancialYear <= $0.creditedDate && $0.creditedDate <= lastDayOfFinancialYear
//            }.count > 0
//            
//            if(financialYearAvailable) {
//                financialYearList.insert("\(nextYear - 1)-\(nextYear)", at: 0)
//            }
//            nextYear = nextYear + 1
//        }
//        
        var incomeListByGroupUpdated = [String: [IncomeRestModel]]()
        
//        if(!financialYearList.isEmpty) {
//            for financialYear in financialYearList {
//                let financialYears = financialYear.split(separator: "-")
//                let calendar = Calendar.current
//                let startDate = DateComponents(
//                    calendar: calendar,
//                    year: financialYears[0].integer,
//                    month: 4,
//                    day: 1,
//                    hour: 0,
//                    minute: 0,
//                    second: 0)
//                
//                let endDate = DateComponents(
//                    calendar: calendar,
//                    year: financialYears[1].integer,
//                    month: 3,
//                    day: 31,
//                    hour: 23,
//                    minute: 59,
//                    second: 59)
//                
//                let filterList = list.filter {
//                    $0.creditedDate <= Calendar.current.date(from: endDate)! && $0.creditedDate >= Calendar.current.date(from: startDate)!
//                }
//                
//                var cumAmount = 0.0
//                var cumTaxPaid = 0.0
//                let returnIncomeList = filterList.reversed().map { value1 in
//                    var sumAmount = 0.0
//                    var sumTaxPaid = 0.0
//                    var totalMonth = 0.0
//                    var totalDays = 0
//                    var maxDays = 0
//                    cumAmount = cumAmount + value1.amount
//                    cumTaxPaid = cumTaxPaid + value1.taxpaid
//                    filterList.reversed().forEach { value2 in
//                        if(value1.creditedDate >= value2.creditedDate) {
//                            sumAmount += value2.amount
//                            sumTaxPaid += value2.taxpaid
//                            
//                            let date = DateComponents(
//                                calendar: Calendar.current,
//                                year: value2.creditedDate.getDateComponents().year,
//                                month: value2.creditedDate.getDateComponents().month,
//                                day: 1)
//                            totalDays = value1.creditedDate.removeTimeStamp().days(from: Calendar.current.date(from: date)!) + 1
//                            maxDays = maxDays < totalDays ? totalDays : maxDays
//                        }
//                    }
//                    totalMonth = Double(maxDays) / Double(30)
//                    return IncomeRestModel(id: value1.id,
//                                             amount: value1.amount,
//                                             taxpaid: value1.taxPaid,
//                                             creditedOn: value1.creditedDate,
//                                             currency: value1.currency,
//                                             type: value1.type,
//                                             tag: value1.tag,
//                                             avgAmount: sumAmount / Double(totalMonth),
//                                             avgTaxPaid: sumTaxPaid / Double(totalMonth),
//                                             cumulativeAmount: cumAmount,
//                                             cumulativeTaxPaid: cumTaxPaid)
//                }
//                incomeListByGroupUpdated.updateValue(returnIncomeList.reversed(), forKey: financialYear)
//            }
//        }
        return incomeListByGroupUpdated
    }
}
