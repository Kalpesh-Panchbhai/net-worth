//
//  NewIncomeTagView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 20/02/23.
//

import SwiftUI

struct NewIncomeTypeView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var incomeController = IncomeController()
    
    @ObservedObject var incomeViewModel : IncomeViewModel
    
    @State private var typeName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Income Type detail") {
                    TextField("Type name", text: $typeName)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        Task.init {
                            incomeController.addIncomeType(tag: IncomeType(name: typeName))
                            await incomeViewModel.getIncomeTypeList()
                        }
                        dismiss()
                    }, label: {
                        Image(systemName: "checkmark")
                    }).disabled(typeName.isEmpty)
                }
            }
        }
    }
}
