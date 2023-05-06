//
//  ImportExportView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 06/05/23.
//

import SwiftUI

struct ImportExportView: View {
    
    private var importExportController = ImportExportController()
    
    @StateObject private var importExportViewModel = ImportExportViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<importExportViewModel.backupList.count, id: \.self, content: { i in
                    if(i == 0) {
                        HStack {
                            Text(importExportViewModel.backupList[i].getDateAndFormat() + " at " + importExportViewModel.backupList[i].getTimeAndFormat())
                            Spacer()
                            Text("Latest")
                                .foregroundColor(.green)
                        }
                    } else {
                        Text(importExportViewModel.backupList[i].getDateAndFormat() + " at " + importExportViewModel.backupList[i].getTimeAndFormat())
                    }
                })
            }
        }
        .onAppear {
            Task.init {
                await importExportViewModel.getAllBackup()
            }
        }
        .toolbar {
            ToolbarItem(content: {
                Button(action: {
                    Task.init {
                        await importExportController.exportLocal()
                        await importExportViewModel.getAllBackup()
                    }
                }, label: {
                    Label("Backup", systemImage: "plus")
                })
            })
        }
    }
}
