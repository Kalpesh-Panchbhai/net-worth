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
    
    @Published var incomeList = [Income]()
    @Published var incomeListLoaded = false
    @Published var incomeTotalAmount = 0.0
    @Published var incomeTaxPaidAmount = 0.0
    
    @Published var incomeTagList = [IncomeTag]()
    @Published var incomeTypeList = [IncomeType]()
    @Published var incomeYearList = [String]()
    @Published var incomeFinancialYearList = [String]()
    
    func getIncomeList(incomeType: String = "", incomeTag: String = "", year: String = "", financialYear: String = "") async {
        do {
            let list = try await incomeController.getIncomeList(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
            DispatchQueue.main.async {
                self.incomeList = list
                self.incomeListLoaded = true
            }
        } catch {
            print(error)
        }
    }
    
    func getTotalBalance(incomeType: String = "", incomeTag: String = "", year: String = "", financialYear: String = "") async {
        do {
            let amount = try await incomeController.fetchTotalAmount(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
            DispatchQueue.main.async {
                self.incomeTotalAmount = amount
            }
        } catch {
            print(error)
        }
    }
    
    func getTotalTaxPaid(incomeType: String = "", incomeTag: String = "", year: String = "", financialYear: String = "") async {
        do {
            let taxPaid = try await incomeController.fetchTotalTaxPaid(incomeType: incomeType, incomeTag: incomeTag, year: year, financialYear: financialYear)
            DispatchQueue.main.async {
                self.incomeTaxPaidAmount = taxPaid
            }
        } catch {
            print(error)
        }
    }
    
    func getIncomeTagList() async {
        do {
            let list = try await incomeController.getIncomeTagList()
            DispatchQueue.main.async {
                self.incomeTagList = list
            }
        } catch {
            print(error)
        }
    }
    
    func getIncomeTypeList() async {
        do {
            let list = try await incomeController.getIncomeTypeList()
            DispatchQueue.main.async {
                self.incomeTypeList = list
            }
        } catch {
            print(error)
        }
    }
    
    func getIncomeYearList() async {
        do {
            let list = try await incomeController.getIncomeYearList()
            DispatchQueue.main.async {
                self.incomeYearList = list
            }
        } catch {
            print(error)
        }
    }
    
    func getIncomeFinancialYearList() async {
        do {
            let list = try await incomeController.getIncomeFinancialYearList()
            DispatchQueue.main.async {
                self.incomeFinancialYearList = list
            }
        } catch {
            print(error)
        }
    }
}
