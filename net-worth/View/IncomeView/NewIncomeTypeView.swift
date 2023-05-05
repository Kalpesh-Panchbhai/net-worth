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
    @State private var isDefault = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Income Type detail") {
                    TextField("Type name", text: $typeName)
                    Toggle("Default Type", isOn: $isDefault)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        Task.init {
                            incomeController.addIncomeType(type: IncomeType(name: typeName, isdefault: isDefault))
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
