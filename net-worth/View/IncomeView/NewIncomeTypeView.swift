//
//  NewIncomeTagView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 20/02/23.
//

import SwiftUI

struct NewIncomeTypeView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var scenePhaseBlur = 0
    
    var incomeController = IncomeController()
    
    @ObservedObject var incomeViewModel : IncomeViewModel
    
    @State private var typeName = ""
    @State private var isDefault = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Income Type detail") {
                    TextField("Type name", text: $typeName)
                        .colorMultiply(Color.navyBlue)
                    Toggle("Make it Default Type", isOn: $isDefault)
                        .foregroundColor(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
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
                        if(typeName.isEmpty) {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.lightBlue.opacity(0.3))
                                .bold()
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.lightBlue)
                                .bold()
                        }
                    })
                    .font(.system(size: 14).bold())
                    .disabled(typeName.isEmpty)
                }
            }
            .navigationTitle("New Income Type")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.navyBlue)
            .scrollContentBackground(.hidden)
        }
        .blur(radius: CGFloat(scenePhaseBlur))
        .onChange(of: scenePhase, perform: { value in
            if(value == .active) {
                scenePhaseBlur = 0
            } else {
                scenePhaseBlur = 5
            }
        })
    }
}
