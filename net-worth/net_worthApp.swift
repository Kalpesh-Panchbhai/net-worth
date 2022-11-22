//
//  net_worthApp.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/11/22.
//

import SwiftUI

@main
struct net_worthApp: App {
    let persistenceController = PersistenceController.shared
    
    private var mutualFundController = MutualFundController()
    
    init() {
        mutualFundController.schedule()
    }

    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
