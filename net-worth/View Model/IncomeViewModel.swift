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
