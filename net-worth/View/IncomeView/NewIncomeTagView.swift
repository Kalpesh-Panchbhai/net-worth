//
//  NewIncomeTagView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 20/02/23.
//

import SwiftUI

struct NewIncomeTagView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var incomeController = IncomeController()
    
    @ObservedObject var incomeViewModel : IncomeViewModel
    
    @State private var tagName = ""
    var body: some View {
        NavigationView {
            Form {
                Section("Income Tag detail") {
                    TextField("Tag name", text: $tagName)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        Task.init {
                            await incomeController.addIncomeTag(tag: IncomeTag(name: tagName))
                            await incomeViewModel.getIncomeTagList()
                        }
                        dismiss()
                    }, label: {
                        Image(systemName: "checkmark")
                    }).disabled(tagName.isEmpty)
                }
            }
        }
    }
}
