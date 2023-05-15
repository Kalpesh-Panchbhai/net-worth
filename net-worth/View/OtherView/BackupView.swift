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
