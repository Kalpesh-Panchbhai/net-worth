//
//  ItemViewController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import Foundation
import SwiftUI

class AccountController {
    
    let viewContext = PersistenceController.shared.container.viewContext
    
    private var notificationController = NotificationController()
    
    private var mutualFundController = MutualFundController()
    
    public func addAccount(accountModel: AccountModel) {
        let newAccount = Account(context: viewContext)
        newAccount.sysid = UUID()
        newAccount.timestamp = Date()
        newAccount.accounttype = accountModel.accountType
        newAccount.accountname =  accountModel.accountName
        newAccount.currentbalance = Double((accountModel.currentBalance as NSString).doubleValue)
        newAccount.totalshare = Double((accountModel.totalShares as NSString).doubleValue)
        newAccount.paymentreminder = accountModel.paymentReminder
        newAccount.paymentdate = Int16(accountModel.paymentDate)
        
        do {
            try viewContext.save()
            if(accountModel.paymentReminder) {
                notificationController.setNotification(id: newAccount.sysid!, day: accountModel.paymentDate, accountType: accountModel.accountType, accountName: accountModel.accountName)
            }
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    public func getAccountTotalBalance() -> Double {
        var balance = 0.0
        let request = Account.fetchRequest()
        var accounts: [Account] = []
        do{
            accounts = try viewContext.fetch(request)
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        for account in accounts {
            if(account.accounttype == "Mutual Fund") {
                let mutualFund = mutualFundController.getMutualFund(name: account.accountname!)
                let currentBalance = account.totalshare * mutualFund.rate!.toDouble()!
                balance += currentBalance
            }else {
                balance += account.currentbalance
            }
        }
        return balance
    }
    
    public func getAccount(uuid: UUID) -> Account {
        let request = Account.fetchRequest()
        request.predicate = NSPredicate(
            format: "sysid = %@", uuid.uuidString
        )
        var account: Account
        do{
            account = try viewContext.fetch(request).first!
        }catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return account
    }
    
    public func deleteAccount(account: Account) {
        viewContext.delete(account)
        do {
            notificationController.removeNotification(id: account.sysid!)
            try viewContext.save()
        }catch {
            viewContext.rollback()
            print("Failed to delete account \(error)")
        }
    }
    
    private let accountFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}
