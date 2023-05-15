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
                //                List {
                //                    ForEach(0..<importExportViewModel.backupList.count, id: \.self, content: { i in
                //                        HStack {
                //                            if(i == 0) {
                //
                //                                Text(importExportViewModel.backupList[i].getDateAndFormat() + " at " + importExportViewModel.backupList[i].getTimeAndFormat())
                //                                Spacer()
                //                                ZStack {
                //                                    RoundedRectangle(cornerRadius: 10)
                //                                        .fill(Color.green.opacity(0.5))
                //                                        .frame(width: 60, height: 15)
                //                                    Text("Latest")
                //                                        .font(.system(size: 10))
                //                                        .bold()
                //                                }
                //                            } else {
                //                                Text(importExportViewModel.backupList[i].getDateAndFormat() + " at " + importExportViewModel.backupList[i].getTimeAndFormat())
                //
                //                            }
                //                        }
                //                        .contextMenu {
                //                            Button(role: .destructive, action: {
                //                                importExportController.deleteBackup(backupDate: importExportViewModel.backupList[i])
                //                                Task.init {
                //                                    await importExportViewModel.getAllBackup()
                //                                }
                //                            }, label: {
                //                                Label("Delete", systemImage: "trash")
                //                            })
                //
                //                            Button(action: {
                //                                let date = importExportViewModel.backupList[i]
                //                                Task.init {
                //                                    await importExportController.importLocal(date: date, importType: "Account")
                //                                }
                //                            }, label: {
                //                                Text("Import Accounts")
                //                            })
                //
                //                            Button(action: {
                //                                let date = importExportViewModel.backupList[i]
                //                                Task.init {
                //                                    await importExportController.importLocal(date: date, importType: "Income")
                //                                }
                //                            }, label: {
                //                                Text("Import Incomes")
                //                            })
                //
                //                            Button(action: {
                //                                let date = importExportViewModel.backupList[i]
                //                                Task.init {
                //                                    await importExportController.importLocal(date: date, importType: "Tag")
                //                                }
                //                            }, label: {
                //                                Text("Import Income tags")
                //                            })
                //
                //                            Button(action: {
                //                                let date = importExportViewModel.backupList[i]
                //                                Task.init {
                //                                    await importExportController.importLocal(date: date, importType: "Type")
                //                                }
                //                            }, label: {
                //                                Text("Import Income types")
                //                            })
                //
                //                            Button(action: {
                //                                let date = importExportViewModel.backupList[i]
                //                                Task.init {
                //                                    await importExportController.importLocal(date: date, importType: "WatchList")
                //                                }
                //                            }, label: {
                //                                Text("Import Watchlists")
                //                            })
                //                        }
                //                    })
                //                    .listRowBackground(Color.white)
                //                    .foregroundColor(Color.navyBlue)
                //                }
                //                .background(Color.navyBlue)
                //                .scrollContentBackground(.hidden)
                List {
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
                }
            }
        }
        .onAppear {
            Task.init {
                await importExportViewModel.getLocalBackup()
            }
        }
        .toolbar {
            ToolbarItem(content: {
                Button(action: {
                    Task.init {
                        await importExportController.exportLocal()
                        await importExportViewModel.getLocalBackup()
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
}
