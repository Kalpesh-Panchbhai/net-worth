//
//  ImportExportViewModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

class ImportExportViewModel: ObservableObject {
    
    @Published var backupList = [Date]()
    @Published var backupData = Data()
    
    private var importExportController = ImportExportController()
    
    func getLocalBackup() async {
        let amount = importExportController.getLocalBackup()
        DispatchQueue.main.async {
            self.backupList = amount
        }
    }
    
    func readLocalBackup() async {
        do {
            let data = try await importExportController.readLocalBackup()
            DispatchQueue.main.async {
                self.backupData = data
            }
        } catch {
            print(error)
        }
    }
}
