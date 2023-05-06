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
                ForEach(importExportViewModel.backupList, id: \.self, content: { item in
                    Text(item)
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
