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
    
    var incomeController = IncomeController()
    var incomeTypeController = IncomeTypeController()
    var incomeTagController = IncomeTagController()
    
    @Published var incomeList = [IncomeCalculation]()
    @Published var incomeListByGroup = [String: [IncomeCalculation]]()
    @Published var incomeListLoaded = false
    @Published var incomeTotalAmount = 0.0
    @Published var incomeTaxPaidAmount = 0.0
    
    @Published var incomeTagList = [IncomeTag]()
    @Published var incomeTypeList = [IncomeType]()
    @Published var incomeYearList = [String]()
    @Published var incomeFinancialYearList = [String]()
    
    func getIncomeList(incomeType: String = "", incomeTag: String = "", year: String = "", financialYear: String = "") async {
        let list = await incomeController.getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
        DispatchQueue.main.async {
            self.incomeList = list
            self.incomeListLoaded = true
        }
    }
    
    func getIncomeListByGroup(incomeType: String = "", incomeTag: String = "", year: String = "", financialYear: String = "", groupBy: String) async {
        let list = await incomeController.getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
        if(groupBy.elementsEqual("Type")) {
            let groupByType = Dictionary(grouping: list, by: {$0.type})
            var incomeListByGroupUpdated = [String: [IncomeCalculation]]()
            
            for (key, value) in groupByType {
                var cumAmount = 0.0
                var cumTaxPaid = 0.0
                let returnIncomeList = value.reversed().map { value1 in
                    var sumAmount = 0.0
                    var sumTaxPaid = 0.0
                    var totalMonth = 0
                    cumAmount = cumAmount + value1.amount
                    cumTaxPaid = cumTaxPaid + value1.taxpaid
                    value.reversed().forEach { value2 in
                        if(value1.creditedOn >= value2.creditedOn) {
                            sumAmount += value2.amount
                            sumTaxPaid += value2.taxpaid
                            totalMonth+=1
                        }
                    }
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
            
            let groupByTypeUpdated = incomeListByGroupUpdated
            
            DispatchQueue.main.async {
                self.incomeListByGroup = groupByTypeUpdated
                self.incomeListLoaded = true
            }
        } else if(groupBy.elementsEqual("Tag")) {
            let groupByTag = Dictionary(grouping: list, by: {$0.tag})
            var incomeListByGroupUpdated = [String: [IncomeCalculation]]()
            
            for (key, value) in groupByTag {
                var cumAmount = 0.0
                var cumTaxPaid = 0.0
                let returnIncomeList = value.reversed().map { value1 in
                    var sumAmount = 0.0
                    var sumTaxPaid = 0.0
                    var totalMonth = 0
                    cumAmount = cumAmount + value1.amount
                    cumTaxPaid = cumTaxPaid + value1.taxpaid
                    value.reversed().forEach { value2 in
                        if(value1.creditedOn >= value2.creditedOn) {
                            sumAmount += value2.amount
                            sumTaxPaid += value2.taxpaid
                            totalMonth+=1
                        }
                    }
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
            
            let groupByTagUpdated = incomeListByGroupUpdated
            
            DispatchQueue.main.async {
                self.incomeListByGroup = groupByTagUpdated
                self.incomeListLoaded = true
            }
        }
    }
    
    func getTotalBalance(incomeType: String = "", incomeTag: String = "", year: String = "", financialYear: String = "") async {
        let amount = await incomeController.fetchTotalAmount(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
        DispatchQueue.main.async {
            self.incomeTotalAmount = amount
        }
    }
    
    func getTotalTaxPaid(incomeType: String = "", incomeTag: String = "", year: String = "", financialYear: String = "") async {
        let taxPaid = await incomeController.fetchTotalTaxPaid(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
        DispatchQueue.main.async {
            self.incomeTaxPaidAmount = taxPaid
        }
    }
    
    func getIncomeTagList() async {
        let list = await incomeTagController.getIncomeTagList()
        DispatchQueue.main.async {
            self.incomeTagList = list
        }
    }
    
    func getIncomeTypeList() async {
        let list = await incomeTypeController.getIncomeTypeList()
        DispatchQueue.main.async {
            self.incomeTypeList = list
        }
    }
    
    func getIncomeYearList() async {
        let list = await incomeController.getIncomeYearList()
        DispatchQueue.main.async {
            self.incomeYearList = list
        }
    }
    
    func getIncomeFinancialYearList() async {
        let list = await incomeController.getIncomeFinancialYearList()
        DispatchQueue.main.async {
            self.incomeFinancialYearList = list
        }
    }
}
