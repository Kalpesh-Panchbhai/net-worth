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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
