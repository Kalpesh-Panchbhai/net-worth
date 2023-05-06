//
//  ImportExportController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import Foundation

class ImportExportController {
    
    private var incomeController = IncomeController()
    private var accountController = AccountController()
    private var watchController = WatchController()
    
    private var data = Data()
    
    public func getAllLocalBackup() -> [Date] {
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
                $0.lastPathComponent.replacingOccurrences(of: "Backup_", with: "").toDate()
            }.sorted().reversed()
            
        } catch {
            print(error)
        }
        
        return [Date]()
        
    }
    
    public func importLocal(date: Date) async {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let pathWithFileName = documentDirectory!.appendingPathComponent("Backup_" + date.formatImportExportTimeStamp())
        
        do {
            let jsonString = try String(contentsOf: pathWithFileName, encoding: .utf8)
            if let dataFromJsonString = jsonString.data(using: .utf8) {
                data = try JSONDecoder().decode(Data.self,
                                                from: dataFromJsonString)
            }
        } catch {
            print(error)
        }
        
        importIncomeTag()
        importIncomeType()
        await importIncome()
        do {
            try await Task.sleep(for: Duration.seconds(5))
        } catch {
            print(error)
        }
        await importAccount()
        do {
            try await Task.sleep(for: Duration.seconds(5))
        } catch {
            print(error)
        }
        await importWatch()
    }
    
    private func importIncomeTag() {
        for tag in data.incomeTag {
            let incomeTag = IncomeTag(name: tag.name, isdefault: tag.isdefault)
            incomeController.addIncomeTag(tag: incomeTag)
        }
    }
    
    private func importIncomeType() {
        for type in data.incomeType {
            let incomeType = IncomeType(name: type.name, isdefault: type.isdefault)
            incomeController.addIncomeType(type: incomeType)
        }
    }
    
    private func importIncome() async {
        for income in data.income {
            await incomeController.addIncome(type: IncomeType(name: income.type, isdefault: false), amount: String(income.amount), date: income.creditedOn, taxPaid: String(income.taxpaid), currency: income.currency, tag: IncomeTag(name: income.tag, isdefault: false))
        }
    }
    
    private func importAccount() async {
        for account in data.account {
            let newAccount = Account(accountType: account.accountType, loanType: account.loanType, accountName: account.accountName, currentBalance: account.currentBalance, paymentReminder: account.paymentReminder, paymentDate: account.paymentDate, currency: account.currency, active: account.active)
            var accountTransaction = account.accountTransaction.sorted(by: {
                $0.timestamp < $1.timestamp
            })
            let accountID = await accountController.addAccount(newAccount: newAccount)
            for i in 0..<accountTransaction.count {
                let newAccountTransaction = AccountTransaction(timestamp: accountTransaction[i].timestamp, balanceChange: accountTransaction[i].balanceChange, currentBalance: accountTransaction[i].currentBalance, paid: accountTransaction[i].paid)
                do {
                    try await accountController.addTransaction(accountID: accountID, accountTransaction: newAccountTransaction)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    private func importWatch() async {
        for watch in data.watch {
            var newWatch = Watch()
            do {
                let accountList = try await accountController.getAccountList()
                newWatch.accountID = watch.accountID.map { accountID in
                    accountList.filter { account in
                        account.accountName.elementsEqual(accountID)
                    }.first?.id ?? ""
                }
                newWatch.accountName = watch.accountName
                watchController.addWatchList(watchList: newWatch)
            } catch {
                print(error)
            }
        }
    }
    
    
    public func exportLocal() async {
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
                let pathWithFileName = documentDirectory.appendingPathComponent("Backup_" + getCurrentDateTimeStamp())
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
    
    private func getCurrentDateTimeStamp() -> String {
        let date = Date.now
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter.string(from: date)
    }
    
    private func exportIncomeTag() async {
        do {
            let incomeTagList = try await incomeController.getIncomeTagList()
            data.incomeTag = incomeTagList.map { item in
                return IncomeTagData(name: item.name, isdefault: item.isdefault)
            }
        } catch {
            print(error)
        }
    }
    
    private func exportIncomeType() async {
        do {
            let incomeTypeList = try await incomeController.getIncomeTypeList()
            data.incomeType = incomeTypeList.map { item in
                return IncomeTypeData(name: item.name, isdefault: item.isdefault)
            }
        } catch {
            print(error)
        }
    }
    
    private func exportIncome() async {
        do {
            let incomeList = try await incomeController.getIncomeList()
            data.income = incomeList.map { item in
                return IncomeData(amount: item.amount, taxpaid: item.taxpaid, creditedOn: item.creditedOn, currency: item.currency, type: item.type, tag: item.tag, avgAmount: item.avgAmount, avgTaxPaid: item.avgTaxPaid, cumulativeAmount: item.cumulativeAmount, cumulativeTaxPaid: item.cumulativeTaxPaid, animate: item.animate)
            }
        } catch {
            print(error)
        }
    }
    
    private func exportAccount() async {
        do {
            let accountList = try await accountController.getAccountList()
            var accountTransactionList = [String: [AccountTransaction]]()
            for account in accountList {
                let accountTransactions = try await accountController.getAccountTransactionList(id: account.id!)
                accountTransactionList.updateValue(accountTransactions, forKey: account.id!)
            }
            
            data.account = accountList.map { account in
                let accountTransaction = accountTransactionList.filter {
                    $0.key.elementsEqual(account.id!)
                }.first?.value.map { accountTransaction in
                    return AccountTransactionData(timestamp: accountTransaction.timestamp, balanceChange: accountTransaction.balanceChange, currentBalance: accountTransaction.currentBalance, paid: accountTransaction.paid)
                }
                return AccountData(accountType: account.accountType, loanType: account.loanType, accountName: account.accountName, currentBalance: account.currentBalance, paymentReminder: account.paymentReminder, paymentDate: account.paymentDate, currency: account.currency, active: account.active, accountTransaction: accountTransaction ?? [AccountTransactionData]())
            }
        } catch {
            print(error)
        }
    }
    
    private func exportWatch() async {
        do {
            let watchList = try await watchController.getAllWatchList()
            let accountList = try await accountController.getAccountList()
            data.watch = watchList.map { watch in
                let accounts = watch.accountID.map { accountID in
                    accountList.filter { account in
                        account.id!.elementsEqual(accountID)
                    }.first!.accountName
                }
                return WatchData(accountName: watch.accountName, accountID: accounts)
            }
        } catch {
            print(error)
        }
    }
}