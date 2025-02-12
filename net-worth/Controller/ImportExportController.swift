//
//  ImportExportController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

class ImportExportController {
    
    var incomeController = IncomeController()
    var incomeTypeController = IncomeTypeController()
    var incomeTagController = IncomeTagController()
    var accountController = AccountController()
    var watchController = WatchController()
    
    var data = BackupModel()
    
    public func importLocal(date: Date, importType: String) async {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let pathWithFileName = documentDirectory!.appendingPathComponent("Backup_" + date.formatImportExportTimeStamp())
        
        do {
            let jsonString = try String(contentsOf: pathWithFileName, encoding: .utf8)
            if let dataFromJsonString = jsonString.data(using: .utf8) {
                data = try JSONDecoder().decode(BackupModel.self,
                                                from: dataFromJsonString)
            }
        } catch {
            print(error)
        }
        if(importType.elementsEqual("Account")) {
            await importAccount()
        } else if(importType.elementsEqual("WatchList")) {
            await importWatch()
        } else if(importType.elementsEqual("Tag")) {
            await importIncomeTag()
        } else if(importType.elementsEqual("Type")) {
            await importIncomeType()
        } else if(importType.elementsEqual("Income")) {
            await importIncome()
        }
    }
    
    private func importIncomeTag() async {
        for tag in data.incomeTag {
            let incomeTag = IncomeTag(name: tag.name, isdefault: tag.isdefault)
            await incomeTagController.addIncomeTag(tag: incomeTag)
        }
    }
    
    private func importIncomeType() async {
        for type in data.incomeType {
            let incomeType = IncomeType(name: type.name, isdefault: type.isdefault)
            await incomeTypeController.addIncomeType(type: incomeType)
        }
    }
    
    private func importIncome() async {
        for income in data.income {
            let income = Income(amount: income.amount, taxpaid: income.taxpaid, creditedOn: income.creditedOn, currency: income.currency, type: income.type, tag: income.tag)
            await incomeController.addIncome(income: income)
        }
    }
    
    private func importAccount() async {
        //        for account in data.account {
        //            let newAccount = Account(accountType: account.accountType, loanType: account.loanType, accountName: account.accountName, currentBalance: account.currentBalance, paymentReminder: account.paymentReminder, paymentDate: account.paymentDate, currency: account.currency, active: account.active)
        //            let accountTransaction = account.accountTransaction.sorted(by: {
        //                $0.timestamp < $1.timestamp
        //            })
        //            await accountController.addAccount(newAccount: newAccount)
        //        }
    }
    
    private func importWatch() async {
//        for watch in data.watch {
//            var newWatch = Watch()
//            let accountList = await accountController.getAccountList()
//            newWatch.accountList = watch.accountID.map { accountID in
//                accountList.filter { account in
//                    account.accountName.elementsEqual(accountID)
//                }.first?.id ?? ""
//            }
//            newWatch.name = watch.accountName
//            await watchController.addWatchList(watch: newWatch)
//        }
    }
    
    public func exportLocal(accountViewModel: AccountViewModel, watchViewModel: WatchViewModel, incomeViewModel: IncomeViewModel) async {
        
        deleteBackups()
        
        await exportIncomeTag(incomeViewModel: incomeViewModel)
        await exportIncomeType(incomeViewModel: incomeViewModel)
        await exportIncome(incomeViewModel: incomeViewModel)
        await exportAccount(accountViewModel: accountViewModel)
        await exportWatch(watchViewModel: watchViewModel, accountViewModel: accountViewModel)
        
        do {
            let encodedData = try JSONEncoder().encode(data)
            let jsonString = String(data: encodedData,
                                    encoding: .utf8)
            
            if let jsonData = jsonString!.data(using: .utf8),
               let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                                                                in: .userDomainMask).first {
                let pathWithFileName = documentDirectory.appendingPathComponent("Backup_" + getCurrentDateTimeStamp() + ".txt")
                do {
                    try jsonData.write(to: pathWithFileName)
                } catch {
                    print(error)
                }
            }
        } catch {
            print(error)
        }
    }
    
    private func exportIncomeTag(incomeViewModel: IncomeViewModel) async {
        let incomeTagList = incomeViewModel.incomeTagList
        data.incomeTag = incomeTagList.map { item in
            return IncomeTagBackupModel(name: item.name, isdefault: item.isdefault)
        }
    }
    
    private func exportIncomeType(incomeViewModel: IncomeViewModel) async {
        let incomeTypeList = incomeViewModel.incomeTypeList
        data.incomeType = incomeTypeList.map { item in
            return IncomeTypeBackupModel(name: item.name, isdefault: item.isdefault)
        }
    }
    
    private func exportIncome(incomeViewModel: IncomeViewModel) async {
        let incomeList = incomeViewModel.incomeList
        data.income = incomeList.map { item in
            return IncomeBackupModel(amount: item.amount, taxpaid: item.taxpaid, creditedOn: item.creditedOn, currency: item.currency, type: item.type, tag: item.tag)
        }
    }
    
    private func exportAccount(accountViewModel: AccountViewModel) async {
//        let accountList = accountViewModel.accountList
//        var accountDataList = [AccountBackupModel]()
//        
//        for account in accountList {
//            if(account.accountType == ConstantUtils.brokerAccountType) {
//                await accountViewModel.getAccountInBrokerList(brokerID: account.id)
//                let accountsInBroker = accountViewModel.accountsInBroker
//                var accountsInBrokerDataList = [AccountInBrokerBackupModel]()
//                for accountInBroker in accountsInBroker {
//                    let accountInBrokerData = AccountInBrokerBackupModel(symbol: accountInBroker.symbol, name: accountInBroker.name, currentUnit: accountInBroker.currentUnit)
//                    accountsInBrokerDataList.append(accountInBrokerData)
//                }
//                
//                let accountData = AccountBackupModel(accountName: account.accountName, accountType: account.accountType, loanType: account.loanType, currency: account.currency, active: account.active, balance: BalanceAccount(), accountInBroker: accountsInBrokerDataList)
//                
//                accountDataList.append(accountData)
//            } else {
//                let accountData = AccountBackupModel(accountName: account.accountName, accountType: account.accountType, loanType: account.loanType, currency: account.currency, active: account.active, balance: account.balance, accountInBroker: [AccountInBrokerBackupModel]())
//                
//                accountDataList.append(accountData)
//            }
//        }
//        data.account = accountDataList
    }
    
    private func exportWatch(watchViewModel: WatchViewModel, accountViewModel: AccountViewModel) async {
//        let watchList = watchViewModel.watchList
//        let accountList = accountViewModel.accountList
//        data.watch = watchList.map { watch in
//            let accounts = watch.accountList.map { accountID in
//                accountList.filter { account in
//                    account.id.elementsEqual(accountID)
//                }.first!.accountName
//            }
//            return WatchBackupModel(accountName: watch.name, accountID: accounts)
//        }
    }
    
    private func getCurrentDateTimeStamp() -> String {
        let date = Date.now
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter.string(from: date)
    }
    
    public func readLocalBackup() async -> BackupModel {
        var returnData = BackupModel()
        do {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: documentDirectory!,
                includingPropertiesForKeys: nil
            )
            
            let backupList = directoryContents.filter {
                $0.lastPathComponent.starts(with: "Backup_")
            }
            
            if(!backupList.isEmpty) {
                do {
                    let jsonString = try String(contentsOf: backupList[0].absoluteURL, encoding: .utf8)
                    if let dataFromJsonString = jsonString.data(using: .utf8) {
                        returnData = try JSONDecoder().decode(BackupModel.self,
                                                              from: dataFromJsonString)
                        
                    }
                } catch {
                    print(error)
                }
            }
        } catch {
            print(error)
        }
        return returnData
    }
    
    public func getLocalBackup() -> [Date] {
        do {
            let documentDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: documentDirectory,
                includingPropertiesForKeys: nil
            )
            
            let backupList = directoryContents.filter {
                $0.lastPathComponent.starts(with: "Backup_")
            }
            
            return backupList.map {
                let fileName = $0.lastPathComponent
                return fileName.replacingOccurrences(of: ".txt", with: "").replacingOccurrences(of: "Backup_", with: "").toDate()
            }.sorted().reversed()
            
        } catch {
            print(error)
        }
        
        return [Date]()
        
    }
    
    public func deleteBackups() {
        do {
            let documentDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: documentDirectory,
                includingPropertiesForKeys: nil
            )
            
            let backupList = directoryContents.filter {
                $0.lastPathComponent.starts(with: "Backup_")
            }
            try backupList.forEach { value in
                try FileManager.default.removeItem(at: value)
            }
        } catch {
            print(error)
        }
    }
}
