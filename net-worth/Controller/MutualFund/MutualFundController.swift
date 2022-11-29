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
    
    @objc
    public func fetch() {
        
        guard let url = URL(string: "https://www.amfiindia.com/spages/NAVAll.txt") else {
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
        result = result.replacingOccurrences(of: "\n", with: ";")
        result = result.replacingOccurrences(of: "\r", with: ";")
        var bodyArr : [String] = result.split{$0 == ";"}.map(String.init);
        bodyArr = bodyArr.filter{ $0 != " "}
        let totalCount = bodyArr.count
        var i = 0
        var name: String = ""
        var rate: Double = 0.0
        var code: Int = 0
        while i < totalCount {
            while(bodyArr[i].integer == nil) {
                i+=1
            }
            code = bodyArr[i].integer!
            i+=3
            name = bodyArr[i]
            i+=1
            if(bodyArr[i] == "N.A.") {
                i+=2
                continue
            }
            rate = bodyArr[i].double!
            i+=2
            while(i < totalCount && bodyArr[i].integer == nil) {
                i+=1
            }
            saveUserData(code: code, name: name, rate: rate)
        }
        if(totalMutualFund != 0) {
            deleteWholeData(totalCount: totalMutualFund)
        }
    }
    
    private func saveUserData(code: Int, name: String, rate: Double) {
        let newMutualFund = Mutualfund(context: viewContext)
        newMutualFund.schemecode = Int32(code)
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
