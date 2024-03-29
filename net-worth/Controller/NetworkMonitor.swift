//
//  NetworkMonitor.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 13/05/23.
//

import Foundation
import Network

class NetworkMonitor: ObservableObject {
    
    let networkMonitor = NWPathMonitor()
    let workerQueue = DispatchQueue(label: "Monitor")
    var isConnected = false

    init() {
        networkMonitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            Task {
                await MainActor.run {
                    self.objectWillChange.send()
                }
            }
        }
        networkMonitor.start(queue: workerQueue)
    }
}
