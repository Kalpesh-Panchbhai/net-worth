//
//  NewIncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI

struct NewIncomeView: View {
    
    var incomeTypes =  ["None", "Salary", "Portfolio","Other"]
    var incomeController = IncomeController()
    var currencyList = CurrencyList().currencyList
    
    @State var scenePhaseBlur = 0
    @State var amount: String = "0.0"
    @State var taxPaid: String = "0.0"
    @State var incomeTypeSelected: IncomeType = IncomeType()
    @State var incomeTagSelected: IncomeTag = IncomeTag()
    @State var date = Date()
    @State var addIncomeTagViewOpen = false
    @State var addIncomeTypeViewOpen = false
    
    @State var currencySelected: Currency = Currency()
    @State var filterCurrencyList = CurrencyList().currencyList
    @State var searchTerm: String = ""
    
    @ObservedObject var incomeViewModel : IncomeViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section("Income detail") {
                    Picker(selection: $incomeTypeSelected, label: Text("Type")) {
                        Text("Select").tag(IncomeType())
                        ForEach(incomeViewModel.incomeTypeList, id: \.self) {
                            Text($0.name).tag($0)
                        }
                    }
                    .foregroundColor(Color.theme.primaryText)
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .onChange(of: amount, perform: { _ in
                                let filtered = amount.filter {"0123456789.".contains($0)}
                                
                                if filtered.contains(".") {
                                    let splitted = filtered.split(separator: ".")
                                    if splitted.count >= 2 {
                                        let preDecimal = String(splitted[0])
                                        if String(splitted[1]).count == 3 {
                                            let afterDecimal = String(splitted[1]).prefix(splitted[1].count - 1)
                                            amount = "\(preDecimal).\(afterDecimal)"
                                        }else {
                                            let afterDecimal = String(splitted[1])
                                            amount = "\(preDecimal).\(afterDecimal)"
                                        }
                                    }else if splitted.count == 1 {
                                        let preDecimal = String(splitted[0])
                                        amount = "\(preDecimal)."
                                    }else {
                                        amount = "0."
                                    }
                                } else if filtered.isEmpty && !amount.isEmpty {
                                    amount = ""
                                } else if !filtered.isEmpty {
                                    amount = filtered
                                }
                            })
                            .multilineTextAlignment(.trailing)
                    }
                    .foregroundColor(Color.theme.primaryText)
                    
                    HStack {
                        Text("Tax Paid")
                        Spacer()
                        TextField("Tax Paid", text: $taxPaid)
                            .keyboardType(.decimalPad)
                            .onChange(of: taxPaid, perform: { _ in
                                let filtered = taxPaid.filter {"0123456789.".contains($0)}
                                
                                if filtered.contains(".") {
                                    let splitted = filtered.split(separator: ".")
                                    if splitted.count >= 2 {
                                        let preDecimal = String(splitted[0])
                                        if String(splitted[1]).count == 3 {
                                            let afterDecimal = String(splitted[1]).prefix(splitted[1].count - 1)
                                            taxPaid = "\(preDecimal).\(afterDecimal)"
                                        }else {
                                            let afterDecimal = String(splitted[1])
                                            taxPaid = "\(preDecimal).\(afterDecimal)"
                                        }
                                    }else if splitted.count == 1 {
                                        let preDecimal = String(splitted[0])
                                        taxPaid = "\(preDecimal)."
                                    }else {
                                        taxPaid = "0."
                                    }
                                } else if filtered.isEmpty && !taxPaid.isEmpty {
                                    taxPaid = ""
                                } else if !filtered.isEmpty {
                                    taxPaid = filtered
                                }
                            })
                            .multilineTextAlignment(.trailing)
                    }
                    .foregroundColor(Color.theme.primaryText)
                    
                    HStack{
                        DatePicker("Credited on", selection: $date, in: ...Date(), displayedComponents: [.date])
                    }
                    .foregroundColor(Color.theme.primaryText)
                    
                    CurrencyPicker(currenySelected: $currencySelected)
                        .foregroundColor(Color.theme.primaryText)
                    
                    Picker(selection: $incomeTagSelected, label: Text("Tag")) {
                        Text("Select").tag(IncomeTag())
                        ForEach(incomeViewModel.incomeTagList, id: \.self) {
                            Text($0.name).tag($0)
                        }
                    }
                    .foregroundColor(Color.theme.primaryText)
                }
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            .toolbar {
                // MARK: ToolbarItem for Checkmark
                ToolbarItem {
                    Button(action: {
                        Task.init {
                            let newIncome = Income(amount: amount.toDouble() ?? 0.0, taxpaid: taxPaid.toDouble() ?? 0.0, creditedOn: date, currency: currencySelected.code, type: incomeTypeSelected.name, tag: incomeTagSelected.name)
                            await incomeController.addIncome(income: newIncome)
                        }
                        dismiss()
                    }, label: {
                        if(!allFieldsFilled()) {
                            Image(systemName: ConstantUtils.checkmarkImageName)
                                .foregroundColor(Color.theme.primaryText.opacity(0.3))
                                .bold()
                        } else {
                            Image(systemName: ConstantUtils.checkmarkImageName)
                                .foregroundColor(Color.theme.primaryText)
                                .bold()
                        }
                    })
                    .font(.system(size: 14).bold())
                    .disabled(!allFieldsFilled())
                }
                // MARK: ToolbarItem to add new Income Type and Income Tag
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu(content: {
                        Button(action: {
                            addIncomeTypeViewOpen.toggle()
                        }, label: {
                            Label("Add Income Type", systemImage: "tray.and.arrow.down")
                        })
                        Button(action: {
                            addIncomeTagViewOpen.toggle()
                        }, label: {
                            Label("Add Income Tag", systemImage: "tag.square")
                        })
                    }, label: {
                        Image(systemName: ConstantUtils.menuImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                }
            }
            .onAppear {
                Task.init {
                    await incomeViewModel.getIncomeTypeList()
                    await incomeViewModel.getIncomeTagList()
                    incomeTypeSelected = incomeViewModel.incomeTypeList.filter { item in
                        item.isdefault
                    }.first ?? IncomeType()
                    incomeTagSelected = incomeViewModel.incomeTagList.filter { item in
                        item.isdefault
                    }.first ?? IncomeTag()
                    
                    if(currencySelected.code.isEmpty) {
                        currencySelected = SettingsController().getDefaultCurrency()
                    }
                }
            }
            .sheet(isPresented: $addIncomeTypeViewOpen, onDismiss: {
                incomeTypeSelected = incomeViewModel.incomeTypeList.filter { item in
                    item.isdefault
                }.first ?? IncomeType()
            }, content: {
                NewIncomeTypeView(incomeViewModel: incomeViewModel)
                    .presentationDetents([.medium])
            })
            .sheet(isPresented: $addIncomeTagViewOpen, onDismiss: {
                incomeTagSelected = incomeViewModel.incomeTagList.filter { item in
                    item.isdefault
                }.first ?? IncomeTag()
            }, content: {
                NewIncomeTagView(incomeViewModel: incomeViewModel)
                    .presentationDetents([.medium])
            })
            .navigationTitle("New Income")
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
    
    private func allFieldsFilled () -> Bool {
        if !incomeTypeSelected.name.isEmpty && !incomeTagSelected.name.isEmpty && !currencySelected.name.isEmpty && !amount.isEmpty && !taxPaid.isEmpty {
            return true
        } else {
            return false
        }
    }
}
