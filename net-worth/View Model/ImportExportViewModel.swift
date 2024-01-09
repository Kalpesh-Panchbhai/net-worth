//
//  ImportExportViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

class ImportExportViewModel: ObservableObject {
    
    var importExportController = ImportExportController()
    
    @Published var backupList = [Date]()
    @Published var backupData = BackupModel()
    
    func getLocalBackup() async {
        let backupList = importExportController.getLocalBackup()
        DispatchQueue.main.async {
            self.backupList = backupList
        }
    }
    
    func readLocalBackup() async {
        let backupData = await importExportController.readLocalBackup()
        DispatchQueue.main.async {
            self.backupData = backupData
        }
    }
}
