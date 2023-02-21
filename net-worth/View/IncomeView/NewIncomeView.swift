//
//  NewIncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI

struct NewIncomeView: View {
    
    @State private var amount: String = "0.0"
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
                    HStack{
                        DatePicker("Credited on", selection: $date, in: ...Date(), displayedComponents: [.date])
                    }
                    currencyPicker
                    Picker(selection: $incomeTagSelected, label: Text("Tag")) {
                        ForEach(incomeViewModel.incomeTagList, id: \.self) {
                            Text($0.name).tag($0)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        Task.init {
                            await incomeController.addIncome(incometype: incomeTypeSelected, amount: amount, date: date, currency: currenySelected.code, tag: incomeTagSelected)
                            await incomeViewModel.getTotalBalance()
                            await incomeViewModel.getIncomeList()
                        }
                        dismiss()
                    }, label: {
                        Image(systemName: "checkmark")
                    }).disabled(!allFieldsFilled())
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu(content: {
                        Button(action: {
                            addIncomeTypeViewOpen.toggle()
                        }, label: {
                            Label("Add Income Type", systemImage: "")
                        })
                        Button(action: {
                            addIncomeTagViewOpen.toggle()
                        }, label: {
                            Label("Add Income Tag", systemImage: "")
                        })
                    }, label: {
                        Image(systemName: "ellipsis")
                    })
                }
            }
            .onAppear {
                Task.init {
                    await incomeViewModel.getIncomeTagList()
                    await incomeViewModel.getIncomeTypeList()
                    incomeTagSelected = incomeViewModel.incomeTagList.filter { item in
                        item.name == "None"
                    }.first ?? IncomeTag()
                    incomeTypeSelected = incomeViewModel.incomeTypeList.filter { item in
                        item.name == "None"
                    }.first ?? IncomeType()
                }
            }
            .sheet(isPresented: $addIncomeTagViewOpen, content: {
                NewIncomeTagView(incomeViewModel: incomeViewModel)
            })
            .sheet(isPresented: $addIncomeTypeViewOpen, content: {
                NewIncomeTypeView(incomeViewModel: incomeViewModel)
            })
            .navigationTitle("New Income")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func allFieldsFilled () -> Bool {
        if !incomeTypeSelected.name.isEmpty {
            if amount.isEmpty {
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
