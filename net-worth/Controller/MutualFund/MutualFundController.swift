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
    
    private var dataFound = false
    
    private var taskCompleted = false
    
    @objc
    public func fetch() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yyyy"
        dateFormatter.timeZone = TimeZone.current
        var date: String = dateFormatter.string(from: Date())
        date = "https://portal.amfiindia.com/DownloadNAVHistoryReport_Po.aspx?frmdt=" + date
        guard let url = URL(string: date) else {
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
            if(!result.contains("<!DOCTYPE")) {
                self.extractResponse(response: result)
            }
        }
        task.resume()
    }
    
    private func extractResponse(response: String) {
        let totalMutualFund = getMutualFundCount()
        var result : String = response;
        result = result.replacingOccurrences(of: "\n", with: "")
        result = result.replacingOccurrences(of: "\r", with: "")
        let bodyArr : [String] = result.split{$0 == ";"}.map(String.init);
        let totalCount = bodyArr.count
        var i = 8
        var nameFound = false
        var name: String = ""
        var rate: Double = 0.0
        while i < totalCount {
            if let dummyRate = bodyArr[i].double {
                rate = dummyRate
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
        deleteWholeData(totalCount: totalMutualFund)
    }
    
    private func saveUserData(name: String, rate: Double) {
        let newMutualFund = Mutualfund(context: viewContext)
        newMutualFund.name = name
        newMutualFund.rate = rate
        do {
            try viewContext.save()
        } catch {
        }
    }
    
    private func deleteWholeData(totalCount: Int) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Mutualfund")
        fetchRequest.fetchLimit = totalCount
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
        } catch _ as NSError {
            // TODO: handle the error
        }
    }
    
    public func getMutualFund(name: String) -> Mutualfund {
        let request = Mutualfund.fetchRequest()
        request.predicate = NSPredicate(
            format: "name = %@", name
        )
        var mutualFund: [Mutualfund]
        do{
            mutualFund = try viewContext.fetch(request)
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return mutualFund.isEmpty ? Mutualfund(context: viewContext) : mutualFund[0]
    }
    
    public func getMutualFundCount() -> Int {
        let request = Mutualfund.fetchRequest()
        var mutualFund: [Mutualfund]
        do{
            mutualFund = try viewContext.fetch(request)
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return mutualFund.isEmpty ? 0 : mutualFund.count
    }
    
}
