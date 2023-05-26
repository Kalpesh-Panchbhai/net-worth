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
    @State var currencyChanged = false
    @State var searchTerm: String = ""
    
    @ObservedObject var incomeViewModel : IncomeViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section("Income detail") {
                    Picker(selection: $incomeTypeSelected, label: Text("Type")) {
                        ForEach(incomeViewModel.incomeTypeList, id: \.self) {
                            Text($0.name).tag($0)
                        }
                    }
                    .colorMultiply(Color.navyBlue)
                    .onChange(of: incomeTypeSelected) { _ in
                        amount="0.0"
                        taxPaid="0.0"
                    }
                    
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
                    .foregroundColor(Color.navyBlue)
                    
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
                    .foregroundColor(Color.navyBlue)
                    
                    HStack{
                        DatePicker("Credited on", selection: $date, in: ...Date(), displayedComponents: [.date])
                    }
                    .colorMultiply(Color.navyBlue)
                    
                    CurrencyPicker(currenySelected: $currencySelected)
                        .colorMultiply(Color.navyBlue)
                    
                    Picker(selection: $incomeTagSelected, label: Text("Tag")) {
                        ForEach(incomeViewModel.incomeTagList, id: \.self) {
                            Text($0.name).tag($0)
                        }
                    }
                    .colorMultiply(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
            }
            .toolbar {
                // MARK: ToolbarItem for Checkmark
                ToolbarItem {
                    Button(action: {
                        Task.init {
                            await incomeController.addIncome(type: incomeTypeSelected, amount: amount, date: date, taxPaid: taxPaid, currency: currencySelected.code, tag: incomeTagSelected)
                        }
                        dismiss()
                    }, label: {
                        if(!allFieldsFilled()) {
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
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color.lightBlue)
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
    
    private func allFieldsFilled () -> Bool {
        if !incomeTypeSelected.name.isEmpty && !incomeTagSelected.name.isEmpty && !currencySelected.name.isEmpty && !amount.isEmpty && !taxPaid.isEmpty {
            return true
        } else {
            return false
        }
    }
}
