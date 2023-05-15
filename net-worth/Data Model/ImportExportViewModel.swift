//
//  ImportExportViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

class ImportExportViewModel: ObservableObject {
    
    @Published var backupList = [Date]()
    
    private var importExportController = ImportExportController()
    
    func getLocalBackup() async {
        let amount = importExportController.getLocalBackup()
        DispatchQueue.main.async {
            self.backupList = amount
        }
    }
}
