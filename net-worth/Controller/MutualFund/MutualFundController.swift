//
//  MutualFund.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/11/22.
//

import Foundation
import CoreData

class MutualFundController {
    
    let viewContext = PersistenceController.shared.container.viewContext
    
    public func schedule() {
        let date = Date.now
        let timer = Timer(fireAt: date, interval: 86400, target: self, selector: #selector(fetch), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
    }
    
    @objc
    private func fetch() {
        guard let url = URL(string: "https://portal.amfiindia.com/DownloadNAVHistoryReport_Po.aspx?frmdt=18-Nov-2022") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200 == httpResponse.statusCode else {
                return
            }
            
            let result = String(data: data, encoding: .utf8) ?? ""
            
            self.extractResponse(response: result)
            
        }
        
        task.resume()
    }
    
    private func extractResponse(response: String) {
        var result : String = response;
        result = result.replacingOccurrences(of: "\n", with: "")
        result = result.replacingOccurrences(of: "\r", with: "")
        let bodyArr : [String] = result.split{$0 == ";"}.map(String.init);
        let totalCount = bodyArr.count
        var i = 8
        var nameFound = false
        var name: String = ""
        var rate: String = ""
        while i < totalCount {
            if let dummyRate = bodyArr[i].double {
                rate = String(dummyRate)
                nameFound = false
                i+=2
                saveUserData(name: name, rate: rate)
                continue
            }else if !nameFound {
                name = bodyArr[i]
                nameFound = true
                i+=1
                continue
            }
            i+=1
        }
    }
    
    func saveUserData(name: String, rate: String) {
        let newMutualFund = Mutualfund(context: viewContext)
        newMutualFund.sysid = UUID()
        newMutualFund.name = name
        newMutualFund.rate = rate
        do {
            try viewContext.save()
        } catch {
//            let nsError = error as NSError
//            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
}
