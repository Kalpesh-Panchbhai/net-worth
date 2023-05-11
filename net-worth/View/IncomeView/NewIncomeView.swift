//
//  NewIncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI

struct NewIncomeView: View {
    
    @State private var amount: String = "0.0"
    @State private var taxPaid: String = "0.0"
    @State private var incomeTypeSelected: IncomeType = IncomeType()
    @State private var incomeTagSelected: IncomeTag = IncomeTag()
    @State private var date = Date()
    @State private var addIncomeTagViewOpen = false
    @State private var addIncomeTypeViewOpen = false
    
    var incomeTypes =  ["None", "Salary", "Portfolio","Other"]
    
    @Environment(\.dismiss) var dismiss
    
    private var incomeController = IncomeController()
    
    @State public var currenySelected: Currency = Currency()
    private var currencyList = CurrencyList().currencyList
    @State private var filterCurrencyList = CurrencyList().currencyList
    @State private var currencyChanged = false
    @State private var searchTerm: String = ""
    
    @ObservedObject var incomeViewModel : IncomeViewModel
    
    init(incomeViewModel: IncomeViewModel) {
        self.incomeViewModel = incomeViewModel
    }
    
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
                    }
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .onChange(of: amount, perform: {_ in
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
                    }
                    .foregroundColor(Color.navyBlue)
                    HStack {
                        Text("Tax Paid")
                        Spacer()
                        TextField("Tax Paid", text: $taxPaid)
                            .keyboardType(.decimalPad)
                            .onChange(of: taxPaid, perform: {_ in
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
                    }
                    .foregroundColor(Color.navyBlue)
                    HStack{
                        DatePicker("Credited on", selection: $date, in: ...Date(), displayedComponents: [.date])
                    }
                    .colorMultiply(Color.navyBlue)
                    currencyPicker
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
                ToolbarItem {
                    Button(action: {
                        Task.init {
                            await incomeController.addIncome(type: incomeTypeSelected, amount: amount, date: date, taxPaid: taxPaid, currency: currenySelected.code, tag: incomeTagSelected)
                            await incomeViewModel.getTotalBalance()
                            await incomeViewModel.getIncomeList()
                            await incomeViewModel.getIncomeTagList()
                            await incomeViewModel.getIncomeTypeList()
                            await incomeViewModel.getIncomeYearList()
                            await incomeViewModel.getIncomeFinancialYearList()
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
    }
    
    private func allFieldsFilled () -> Bool {
        if !incomeTypeSelected.name.isEmpty && !incomeTagSelected.name.isEmpty{
            if amount.isEmpty || taxPaid.isEmpty {
                return false
            } else {
                return true
            }
        }else {
            return false
        }
    }
    
    var currencyPicker: some View {
        Picker("Currency", selection: $currenySelected) {
            SearchBar(text: $searchTerm, placeholder: "Search currency")
            ForEach(filterCurrencyList, id: \.self) { (data) in
                defaultCurrencyPickerRightVersionView(currency: data)
                .tag(data)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onChange(of: searchTerm) { (data) in
            if(!data.isEmpty) {
                filterCurrencyList = currencyList.filter({
                    $0.name.lowercased().contains(searchTerm.lowercased()) || $0.symbol.lowercased().contains(searchTerm.lowercased()) || $0.code.lowercased().contains(searchTerm.lowercased())
                })
            } else {
                filterCurrencyList = currencyList
            }
        }
        .onChange(of: currenySelected) { (data) in
            currenySelected = data
            currencyChanged = true
        }
        .onAppear{
            if(!currencyChanged){
                currenySelected = SettingsController().getDefaultCurrency()
            }
        }
        .pickerStyle(.navigationLink)
    }
}
