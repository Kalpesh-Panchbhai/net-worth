//
//  ApplicationData.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/06/23.
//

import Foundation

struct ApplicationData: Codable {
    
    static var shared = ApplicationData()
    
    var accountList: [Account: [AccountTransaction]]
    var accountListUpdatedDate: Date
    
    var data: Data
    
    var dataLoading = false
    
    private init() {
        accountList = [Account: [AccountTransaction]]()
        accountListUpdatedDate = Date().getEarliestDate().addingTimeInterval(-86400)
        
        data = Data()
    }
    
    public static func loadData() async {
        shared.dataLoading = true
        if let data = UserDefaults.standard.data(forKey: "data") {
            do {
                let decoder = JSONDecoder()
                
                shared.data = try decoder.decode(Data.self, from: data)
                
                if(await UserController().isNewIncomeAvailable()) {
                    await loadUserData()
                    await loadIncomeData()
                    
                    do {
                        let encoder = JSONEncoder()
                        
                        let data = try encoder.encode(shared.data)
                        
                        UserDefaults.standard.set(data, forKey: "data")
                        
                    } catch {
                        print("Unable to Encode Note (\(error))")
                    }
                }
            } catch {
                print("Unable to Decode Note (\(error))")
            }
        }else {
            await loadUserData()
            await loadIncomeData()
            
            do {
                let encoder = JSONEncoder()
                
                let data = try encoder.encode(shared.data)
                
                UserDefaults.standard.set(data, forKey: "data")
                
            } catch {
                print("Unable to Encode Note (\(error))")
            }
        }
        shared.dataLoading = false
    }
    
    public static func clear() {
        shared = ApplicationData()
        UserDefaults.standard.removeObject(forKey: "data")
    }
    
    private static func loadIncomeData() async {
        let incomeDataList = await IncomeController().getIncomeList()
        shared.data.incomeDataList = incomeDataList.map {
            return IncomeData(income: Income(id: $0.id!, amount: $0.amount, taxpaid: $0.taxpaid, creditedOn: $0.creditedOn, currency: $0.currency, type: $0.type, tag: $0.tag))
        }
    }
    
    private static func loadUserData() async {
        let user = await UserController().getCurrentUser()
        shared.data.userData = user
        shared.data.incomeDataListUpdatedDate = user.incomeDataUpdatedDate
    }
}
