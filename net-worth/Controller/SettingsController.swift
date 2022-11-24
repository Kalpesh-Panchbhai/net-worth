//
//  SetingsController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import Foundation
import CoreData
import SwiftUI

class SettingsController {
    
    let viewContext = PersistenceController.shared.container.viewContext
    
    private var authentication: Authentication
    
    private var mutualFundController = MutualFundController()
    
    init() {
        authentication = Authentication(context: viewContext)
    }
    
    public func changeAuthentication(isRequired: Bool) {
        authentication.require = isRequired
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func isAuthenticationAvailable() -> Bool {
        let request = Authentication.fetchRequest()
        var authentication: [Authentication] = []
        do{
            authentication = try viewContext.fetch(request)
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return authentication.first!.require
    }
    
    public func isAuthenticationRequire() -> Bool {
        let request = Authentication.fetchRequest()
        var authentication: [Authentication] = []
        do{
            authentication = try viewContext.fetch(request)
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return authentication.isEmpty ? defaultAuthentication() : isAuthenticationAvailable()
    }
    
    private func defaultAuthentication() -> Bool {
        authentication.require = false
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return false
    }
    
    public func updateMutualFundData() {
        if(!mutualFundController.fetch(lastDay: false)) {
            mutualFundController.fetch(lastDay: true)
        }
    }
    
}
