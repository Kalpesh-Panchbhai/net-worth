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
    var selectedGroupBy = ""
    var selectedIncomeTypeList = [String]()
    var selectedIncomeTagList = [String]()
    var selectedYearList = [String]()
    var selectedFinancialYearList = [String]()
    
    @Published var incomeList = [IncomeCalculation]()
    @Published var incomeListByGroup = [String: [IncomeCalculation]]()
    @Published var incomeListLoaded = false
    @Published var incomeTotalAmount = 0.0
    @Published var incomeTaxPaidAmount = 0.0
    
    @Published var incomeTagList = [IncomeTag]()
    @Published var incomeTypeList = [IncomeType]()
    @Published var incomeYearList = [String]()
    @Published var incomeFinancialYearList = [String]()
    
    @Published var groupView = false
    
    func getIncomeList(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String]()) async {
        DispatchQueue.main.async {
            self.incomeListLoaded = false
            self.groupView = false
        }
        
        let list = await incomeController.getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
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
        
        let list = await incomeController.getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
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
        let amount = await incomeController.fetchTotal(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear, field: "Amount")
        DispatchQueue.main.async {
            self.incomeTotalAmount = amount
        }
    }
    
    func getTotalTaxPaid(incomeType: [String] = [String](), incomeTag: [String] = [String](), year: [String] = [String](), financialYear: [String] = [String]()) async {
        let amount = await incomeController.fetchTotal(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear, field: "Tax")
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
        let incomeYearList = await incomeController.getIncomeYearList()
        DispatchQueue.main.async {
            self.incomeYearList = incomeYearList
        }
    }
    
    func getIncomeFinancialYearList() async {
        let incomeFinancialYearList = await incomeController.getIncomeFinancialYearList()
        DispatchQueue.main.async {
            self.incomeFinancialYearList = incomeFinancialYearList
        }
    }
}
