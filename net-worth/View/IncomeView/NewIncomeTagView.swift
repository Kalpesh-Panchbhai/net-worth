//
//  NewIncomeTagView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 20/02/23.
//

import SwiftUI

struct NewIncomeTagView: View {
    
    var incomeController = IncomeController()
    var incomeTagController = IncomeTagController()
    
    @State var scenePhaseBlur = 0
    @State var tagName = ""
    @State var isDefault = false
    
    @StateObject var incomeViewModel : IncomeViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section("Income Tag detail") {
                    TextField("Tag name", text: $tagName)
                    Toggle("Default Tag", isOn: $isDefault)
                }
                .listRowBackground(Color.theme.background)
                .foregroundColor(Color.theme.text)
            }
            .shadow(color: Color.theme.text.opacity(0.3), radius: 10, x: 0, y: 5)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        Task.init {
                            await incomeTagController.addIncomeTag(tag: IncomeTag(name: tagName, isdefault: isDefault))
                            await incomeViewModel.getIncomeTagList()
                        }
                        dismiss()
                    }, label: {
                        if(tagName.isEmpty) {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.theme.text.opacity(0.3))
                                .bold()                                
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.theme.text)
                                .bold()
                        }
                    })
                    .font(.system(size: 14).bold())
                    .disabled(tagName.isEmpty)
                }
            }
            .navigationTitle("New Income Tag")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.theme.background)
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
