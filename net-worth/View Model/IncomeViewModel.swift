//
//  IncomeViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/02/23.
//

import Foundation
import Firebase

class IncomeViewModel: ObservableObject {
    
    var incomeController = IncomeController()
    var incomeTypeController = IncomeTypeController()
    var incomeTagController = IncomeTagController()
    var selectedGroupBy = ""
    var selectedIncomeTypeList = [String]()
    var selectedIncomeTagList = [String]()
    var selectedYearList = [String]()
    var selectedFinancialYearList = [String]()
    
    @Published var incomeList = [IncomeCalculation]()
    @Published var incomeListNew = [Income]()
    @Published var incomeListByGroup = [String: [IncomeCalculation]]()
    @Published var incomeListLoaded = false
    @Published var incomeTotalAmount = 0.0
    @Published var incomeTaxPaidAmount = 0.0
    
    @Published var incomeTagList = [IncomeTag]()
    @Published var incomeTypeList = [IncomeType]()
    @Published var incomeYearList = [String]()
    @Published var incomeFinancialYearList = [String]()
    
    @Published var groupView = false
    
    func getIncomeList() async {
        DispatchQueue.main.async {
            self.incomeListLoaded = false
            self.groupView = false
        }
        let list = await incomeController.getIncomeList()
        var cumAmount = 0.0
        var cumTaxPaid = 0.0
        let returnIncomeList = list.map { value1 in
            var sumAmount = 0.0
            var sumTaxPaid = 0.0
            var totalMonth = 0.0
            var totalDays = 0
            var maxDays = 0
            cumAmount = cumAmount + value1.amount
            cumTaxPaid = cumTaxPaid + value1.taxpaid
            incomeList.forEach { value2 in
                if(value1.creditedDate >= value2.creditedDate) {
                    sumAmount += value2.amount
                    sumTaxPaid += value2.taxpaid
                    
                    let date = DateComponents(
                        calendar: Calendar.current,
                        year: value2.creditedDate.getDateComponents().year,
                        month: value2.creditedDate.getDateComponents().month,
                        day: 1)
                    totalDays = value1.creditedDate.removeTimeStamp().days(from: Calendar.current.date(from: date)!) + 1
                    maxDays = maxDays < totalDays ? totalDays : maxDays
                }
            }
            totalMonth = Double(maxDays) / Double(30)
            return IncomeCalculation(id: value1.id,
                                     amount: value1.amount,
                                     taxpaid: value1.taxpaid,
                                     creditedOn: value1.creditedDate,
                                     currency: value1.currency,
                                     type: value1.type,
                                     tag: value1.tag,
                                     avgAmount: sumAmount / totalMonth,
                                     avgTaxPaid: sumTaxPaid / totalMonth,
                                     cumulativeAmount: cumAmount,
                                     cumulativeTaxPaid: cumTaxPaid)
        }
        DispatchQueue.main.async {
            self.incomeListNew = list
            self.incomeList = returnIncomeList.reversed()
            self.incomeListLoaded = true
        }
    }
    
    func getIncomeList(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String]()) async {
        DispatchQueue.main.async {
            self.incomeListLoaded = false
            self.groupView = false
        }
        
        let list = await incomeController.getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear, incomeList: incomeListNew)
        DispatchQueue.main.async {
            self.incomeList = list
            self.incomeListLoaded = true
        }
    }
    
    func getIncomeListByGroup(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String](), groupBy: String) async {
        DispatchQueue.main.async {
            self.incomeListLoaded = false
            self.groupView = true
        }
        
        let list = await incomeController.getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear, incomeList: incomeListNew)
        if(!list.isEmpty) {
            let incomeListByGroup = incomeController.incomeListGroupBy(list: list, groupBy: groupBy)
            
            DispatchQueue.main.async {
                self.incomeListByGroup = incomeListByGroup
                self.incomeListLoaded = true
            }
        } else {
            DispatchQueue.main.async {
                self.incomeListByGroup = [String: [IncomeCalculation]]()
                self.incomeListLoaded = true
            }
        }
    }
    
    func getTotalBalance(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String]()) async {
        let amount = await incomeController.fetchTotal(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear, field: "Amount", income: incomeListNew)
        DispatchQueue.main.async {
            self.incomeTotalAmount = amount
        }
    }
    
    func getTotalTaxPaid(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String]()) async {
        let amount = await incomeController.fetchTotal(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear, field: "Tax", income: incomeListNew)
        DispatchQueue.main.async {
            self.incomeTaxPaidAmount = amount
        }
    }
    
    func getIncomeTagList() async {
        let incomeTagList = await incomeTagController.getIncomeTagList()
        DispatchQueue.main.async {
            self.incomeTagList = incomeTagList
        }
    }
    
    func getIncomeTypeList() async {
        let incomeTypeList = await incomeTypeController.getIncomeTypeList()
        DispatchQueue.main.async {
            self.incomeTypeList = incomeTypeList
        }
    }
    
    func getIncomeYearList() async {
        let incomeYearList = await incomeController.getIncomeYearList(income: incomeListNew)
        DispatchQueue.main.async {
            self.incomeYearList = incomeYearList
        }
    }
    
    func getIncomeFinancialYearList() async {
        let incomeFinancialYearList = await incomeController.getIncomeFinancialYearList(income: incomeListNew)
        DispatchQueue.main.async {
            self.incomeFinancialYearList = incomeFinancialYearList
        }
    }
}
