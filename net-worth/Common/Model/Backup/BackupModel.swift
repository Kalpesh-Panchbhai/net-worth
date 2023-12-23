//
//  BackupModel.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

struct BackupModel: Codable {
    
    var incomeTag: [IncomeTagBackupModel]
    var incomeType: [IncomeTypeBackupModel]
    var income: [IncomeBackupModel]
    var account: [AccountBackupModel]
    var watch: [WatchBackupModel]
    
    init() {
        self.incomeTag = [IncomeTagBackupModel]()
        self.incomeType = [IncomeTypeBackupModel]()
        self.income = [IncomeBackupModel]()
        self.account = [AccountBackupModel]()
        self.watch = [WatchBackupModel]()
    }
}
