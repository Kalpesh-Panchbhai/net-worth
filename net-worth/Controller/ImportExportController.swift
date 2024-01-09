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
    var accountInBrokerController = AccountInBrokerController()
    var accountTransactionController = AccountTransactionController()
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
        for account in data.account {
            let newAccount = Account(accountType: account.accountType, loanType: account.loanType, accountName: account.accountName, currentBalance: account.currentBalance, paymentReminder: account.paymentReminder, paymentDate: account.paymentDate, currency: account.currency, active: account.active)
            let accountTransaction = account.accountTransaction.sorted(by: {
                $0.timestamp < $1.timestamp
            })
            let accountID = await accountController.addAccount(newAccount: newAccount)
            for i in 0..<accountTransaction.count {
                let newAccountTransaction = AccountTransaction(timestamp: accountTransaction[i].timestamp, balanceChange: accountTransaction[i].balanceChange, currentBalance: accountTransaction[i].currentBalance, paid: accountTransaction[i].paid)
                await accountTransactionController.addTransaction(accountID: accountID, accountTransaction: newAccountTransaction)
            }
        }
    }
    
    private func importWatch() async {
        for watch in data.watch {
            var newWatch = Watch()
            let accountList = accountController.getAccountList()
            newWatch.accountID = watch.accountID.map { accountID in
                accountList.filter { account in
                    account.accountName.elementsEqual(accountID)
                }.first?.id ?? ""
            }
            newWatch.accountName = watch.accountName
            watchController.addWatchList(watchList: newWatch)
        }
    }
    
    public func exportLocal() async {
        
        deleteBackups()
        
        await exportIncomeTag()
        await exportIncomeType()
        await exportIncome()
        await exportAccount()
        await exportWatch()
        
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
    
    private func exportIncomeTag() async {
        let incomeTagList = await incomeTagController.getIncomeTagList()
        data.incomeTag = incomeTagList.map { item in
            return IncomeTagBackupModel(name: item.name, isdefault: item.isdefault)
        }
    }
    
    private func exportIncomeType() async {
        let incomeTypeList = await incomeTypeController.getIncomeTypeList()
        data.incomeType = incomeTypeList.map { item in
            return IncomeTypeBackupModel(name: item.name, isdefault: item.isdefault)
        }
    }
    
    private func exportIncome() async {
        let incomeList = ApplicationData.shared.data.incomeDataList
        data.income = incomeList.map { item in
            return IncomeBackupModel(amount: item.income.amount, taxpaid: item.income.taxpaid, creditedOn: item.income.creditedOn, currency: item.income.currency, type: item.income.type, tag: item.income.tag)
        }
    }
    
    private func exportAccount() async {
        let accountList = accountController.getAccountList()
        var accountDataList = [AccountBackupModel]()
        
        for account in accountList {
            if(account.accountType == ConstantUtils.brokerAccountType) {
                let accountsInBroker = accountInBrokerController.getAccountListInBroker(brokerID: account.id!)
                var accountsInBrokerDataList = [AccountInBrokerBackupModel]()
                for accountInBroker in accountsInBroker {
                    let accountTransactions = accountInBrokerController.getAccountTransactionListInAccountInBroker(brokerID: account.id!, accountID: accountInBroker.id!)
                    let accountTransactionsData = accountTransactions.map { accountTransaction in
                        return AccountTransactionBackupModel(timestamp: accountTransaction.timestamp, balanceChange: accountTransaction.balanceChange, currentBalance: accountTransaction.currentBalance, paid: accountTransaction.paid)
                        
                    }
                    let accountInBrokerData = AccountInBrokerBackupModel(timestamp: accountInBroker.timestamp, symbol: accountInBroker.symbol, name: accountInBroker.name, currentUnit: accountInBroker.currentUnit, accountTransaction: accountTransactionsData)
                    accountsInBrokerDataList.append(accountInBrokerData)
                }
                
                let accountData = AccountBackupModel(accountType: account.accountType, loanType: account.loanType, accountName: account.accountName, currentBalance: account.currentBalance, paymentReminder: account.paymentReminder, paymentDate: account.paymentDate, currency: account.currency, active: account.active, accountInBroker: accountsInBrokerDataList, accountTransaction: [AccountTransactionBackupModel]())
                
                accountDataList.append(accountData)
            } else {
                let accountTransactions = accountTransactionController.getAccountTransactionList(accountID: account.id!)
                let accountTransactionsData = accountTransactions.map { accountTransaction in
                    return AccountTransactionBackupModel(timestamp: accountTransaction.timestamp, balanceChange: accountTransaction.balanceChange, currentBalance: accountTransaction.currentBalance, paid: accountTransaction.paid)
                    
                }
                
                let accountData = AccountBackupModel(accountType: account.accountType, loanType: account.loanType, accountName: account.accountName, currentBalance: account.currentBalance, paymentReminder: account.paymentReminder, paymentDate: account.paymentDate, currency: account.currency, active: account.active, accountInBroker: [AccountInBrokerBackupModel](), accountTransaction: accountTransactionsData)
                
                accountDataList.append(accountData)
            }
        }
        data.account = accountDataList
    }
    
    private func exportWatch() async {
        let watchList = await watchController.getAllWatchList()
        let accountList = accountController.getAccountList()
        data.watch = watchList.map { watch in
            let accounts = watch.accountID.map { accountID in
                accountList.filter { account in
                    account.id!.elementsEqual(accountID)
                }.first!.accountName
            }
            return WatchBackupModel(accountName: watch.accountName, accountID: accounts)
        }
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
    
    func deleteData() async {
        await accountController.deleteAccounts()
        incomeController.deleteIncomes()
        await watchController.deleteWatchLists()
        incomeTagController.deleteIncomeTags()
        incomeTypeController.deleteIncomeTypes()    }
}
