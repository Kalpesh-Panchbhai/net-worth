//
//  ImportExportView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import SwiftUI

struct BackupView: View {
    
    private var importExportController = ImportExportController()
    
    @StateObject private var importExportViewModel = ImportExportViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            if(importExportViewModel.backupList.isEmpty) {
                ZStack {
                    Color.navyBlue.ignoresSafeArea()
                    HStack {
                        Text("Click on")
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text("Icon to backup data.")
                    }
                    .foregroundColor(Color.lightBlue)
                    .bold()
                }
            } else {
                List {
                    VStack {
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
                    .listRowBackground(Color.white)
                    .foregroundColor(Color.navyBlue)
                }
                .background(Color.navyBlue)
                .scrollContentBackground(.hidden)
            }
        }
        .onAppear {
            Task.init {
                await importExportViewModel.getLocalBackup()
                await importExportViewModel.readLocalBackup()
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
                        .foregroundColor(Color.lightBlue)
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
                    .foregroundColor(Color.lightBlue)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
    }
    
    var account: some View {
        HStack {
            Text("Total Accounts")
            Spacer()
            Text("\(importExportViewModel.backupData.account.count)")
        }
    }
    
    var accountTransactions: some View {
        HStack {
            Text("Total Accounts Transactions")
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
    
    var income: some View {
        HStack {
            Text("Total Incomes")
            Spacer()
            Text("\(importExportViewModel.backupData.income.count)")
        }
    }
    
    var incomeType: some View {
        HStack {
            Text("Total Income Type")
            Spacer()
            Text("\(importExportViewModel.backupData.incomeType.count)")
        }
    }
    
    var incomeTag: some View {
        HStack {
            Text("Total Income Tag")
            Spacer()
            Text("\(importExportViewModel.backupData.incomeTag.count)")
        }
    }
    
    var watchList: some View {
        HStack {
            Text("Total WatchLists")
            Spacer()
            Text("\(importExportViewModel.backupData.watch.count)")
        }
    }
}
