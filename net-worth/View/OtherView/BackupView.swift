//
//  ImportExportView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import SwiftUI

struct BackupView: View {
    
    var importExportController = ImportExportController()
    var accountController = AccountController()
    var accountTransactionController = AccountTransactionController()
    var incomeController = IncomeController()
    var incomeTypeController = IncomeTypeController()
    var incomeTagController = IncomeTagController()
    var watchController = WatchController()
    
    @State var totalAccountInCloud = 0
    @State var totalAccountTransactionInCloud = 0
    @State var totalIncomeInCloud = 0
    @State var totalWatchListInCloud = 0
    @State var totalIncomeTypeInCloud = 0
    @State var totalIncomeTagInCloud = 0
    
    @StateObject var importExportViewModel = ImportExportViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section() {
                    VStack(alignment: .leading) {
                        Text("Data in Local Backup")
                            .bold()
                        Divider()
                        HStack {
                            Image(systemName: "checkmark.icloud")
                                .font(.system(size: 40))
                            if(importExportViewModel.backupList.count > 0) {
                                Text("Last Backup: " + importExportViewModel.backupList[0].getDateAndFormat() + ", " + importExportViewModel.backupList[0].getTimeAndFormat())
                                    .font(.system(size: 12))
                            } else {
                                Text("Last Backup: -")
                                    .font(.system(size: 12))
                            }
                        }
                        Divider()
                        account
                        accountTransactions
                        income
                        watchList
                        incomeTag
                        incomeType
                    }
                    .listRowBackground(Color.theme.foreground)
                    .foregroundColor(Color.theme.primaryText)
                }
                
                Section() {
                    VStack(alignment: .leading) {
                        Text("Data in Cloud")
                            .bold()
                        Divider()
                        accountInCloud
                        accountTransactionInCloud
                        incomeInCloud
                        watchListInCloud
                        incomeTagInCloud
                        incomeTypeInCloud
                    }
                    .listRowBackground(Color.theme.foreground)
                    .foregroundColor(Color.theme.primaryText)
                }
            }
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
        }
        .onAppear {
            Task.init {
                await importExportViewModel.getLocalBackup()
                await importExportViewModel.readLocalBackup()
                
                await getTotalAccountInCloud()
                await getTotalAccountTransactionInCloud()
                await getTotalIncomeInCloud()
                await getTotalWatchListInCloud()
                await getTotalIncomeTagInCloud()
                await getTotalIncomeTypeInCloud()
            }
        }
        .toolbar {
            ToolbarItem(content: {
                Button(action: {
                    Task.init {
                        await importExportController.exportLocal()
                        await importExportViewModel.getLocalBackup()
                        await importExportViewModel.readLocalBackup()
                    }
                }, label: {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                })
                .font(.system(size: 14).bold())
            })
        }
        .navigationTitle("Backup")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
    }
    
    private var account: some View {
        HStack {
            Text("Accounts")
            Spacer()
            Text("\(importExportViewModel.backupData.account.count)")
        }
    }
    
    private var accountTransactions: some View {
        HStack {
            Text("Accounts Transactions")
            Spacer()
            Text("\(getTotalTransaction())")
        }
    }
    
    private func getTotalTransaction() -> Int {
        var totalTransactions = 0
        importExportViewModel.backupData.account.forEach {
            totalTransactions += $0.accountTransaction.count
        }
        
        return totalTransactions
    }
    
    private var income: some View {
        HStack {
            Text("Incomes")
            Spacer()
            Text("\(importExportViewModel.backupData.income.count)")
        }
    }
    
    private var watchList: some View {
        HStack {
            Text("WatchLists")
            Spacer()
            Text("\(importExportViewModel.backupData.watch.count)")
        }
    }
    
    private var incomeTag: some View {
        HStack {
            Text("Income Tag")
            Spacer()
            Text("\(importExportViewModel.backupData.incomeTag.count)")
        }
    }
    
    private var incomeType: some View {
        HStack {
            Text("Income Type")
            Spacer()
            Text("\(importExportViewModel.backupData.incomeType.count)")
        }
    }
    
    private var accountInCloud: some View {
        HStack {
            Text("Accounts")
            Spacer()
            Text("\(totalAccountInCloud)")
        }
    }
    
    private func getTotalAccountInCloud() async {
        totalAccountInCloud = await accountController.getAccountList().count
    }
    
    private var accountTransactionInCloud: some View {
        HStack {
            Text("Accounts Transactions")
            Spacer()
            Text("\(totalAccountTransactionInCloud)")
        }
    }
    
    private func getTotalAccountTransactionInCloud() async {
        let accountlist = await accountController.getAccountList()
        for account in accountlist {
            totalAccountTransactionInCloud += accountTransactionController.getAccountTransactionList(accountID: account.id!).count
        }
    }
    
    private var incomeInCloud: some View {
        HStack {
            Text("Incomes")
            Spacer()
            Text("\(totalIncomeInCloud)")
        }
    }
    
    private func getTotalIncomeInCloud() async {
        totalIncomeInCloud = await incomeController.getIncomeList().count
    }
    
    private var watchListInCloud: some View {
        HStack {
            Text("WatchLists")
            Spacer()
            Text("\(totalWatchListInCloud)")
        }
    }
    
    private func getTotalWatchListInCloud() async {
        totalWatchListInCloud = await watchController.getAllWatchList().count
    }
    
    private var incomeTypeInCloud: some View {
        HStack {
            Text("Income Type")
            Spacer()
            Text("\(totalIncomeTypeInCloud)")
        }
    }
    
    private func getTotalIncomeTypeInCloud() async {
        totalIncomeTypeInCloud = await incomeTypeController.getIncomeTypeList().count
    }
    
    private var incomeTagInCloud: some View {
        HStack {
            Text("Income Tag")
            Spacer()
            Text("\(totalIncomeTagInCloud)")
        }
    }
    
    private func getTotalIncomeTagInCloud() async {
        totalIncomeTagInCloud = await incomeTagController.getIncomeTagList().count
    }
}
