//
//  UpdateIncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 20/08/23.
//

import SwiftUI

struct UpdateIncomeView: View {
    
    var income: IncomeRestModel
    var incomeController = IncomeController()
    var currencyList = CurrencyList().currencyList
    
    @State var amount: String = "0.0"
    @State var taxPaid: String = "0.0"
    @State var incomeTypeSelected: TypeValueRestModel = TypeValueRestModel()
    @State var incomeTagSelected: TypeValueRestModel = TypeValueRestModel()
    @State var currencySelected: Currency = Currency()
    @State var date = Date().getEarliestDate()
    
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Income detail") {
                    Picker(selection: $incomeTypeSelected, label: Text("Type")) {
                        Text("Select").tag(TypeValueRestModel())
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
                        Text("Select").tag(TypeValueRestModel())
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
//                            let updatedIncome = IncomeRestModel(id: income.id,amount: amount.toDouble() ?? 0.0, taxPaid: taxPaid.toDouble() ?? 0.0, creditedDate: date, currency: currencySelected.code, type: incomeTypeSelected.name, tag: incomeTagSelected.name)
//                            await incomeController.updateIncome(income: updatedIncome)
//                            await incomeViewModel.getIncomeList()
                            
                            if(incomeViewModel.groupView) {
                                await incomeViewModel.getTotalBalance(incomeType: incomeViewModel.selectedIncomeTypeList, incomeTag: incomeViewModel.selectedIncomeTagList, year: incomeViewModel.selectedYearList, financialYear: incomeViewModel.selectedFinancialYearList)
                                await incomeViewModel.getTotalTaxPaid(incomeType: incomeViewModel.selectedIncomeTypeList, incomeTag: incomeViewModel.selectedIncomeTagList, year: incomeViewModel.selectedYearList, financialYear: incomeViewModel.selectedFinancialYearList)
                                await incomeViewModel.getIncomeListByGroup(incomeType: incomeViewModel.selectedIncomeTypeList, incomeTag: incomeViewModel.selectedIncomeTagList, year: incomeViewModel.selectedYearList, financialYear: incomeViewModel.selectedFinancialYearList, groupBy: incomeViewModel.selectedGroupBy)
                            } else {
                                await incomeViewModel.getTotalBalance(incomeType: incomeViewModel.selectedIncomeTypeList, incomeTag: incomeViewModel.selectedIncomeTagList, year: incomeViewModel.selectedYearList, financialYear: incomeViewModel.selectedFinancialYearList)
                                await incomeViewModel.getTotalTaxPaid(incomeType: incomeViewModel.selectedIncomeTypeList, incomeTag: incomeViewModel.selectedIncomeTagList, year: incomeViewModel.selectedYearList, financialYear: incomeViewModel.selectedFinancialYearList)
                                await incomeViewModel.getIncomeList(incomeType: incomeViewModel.selectedIncomeTypeList, incomeTag: incomeViewModel.selectedIncomeTagList, year: incomeViewModel.selectedYearList, financialYear: incomeViewModel.selectedFinancialYearList)
                            }
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
            }
            .onAppear {
                Task.init {
                    if(incomeTypeSelected.name.isEmpty) {
                        incomeTypeSelected = incomeViewModel.incomeTypeList.filter { item in
                            item.name.elementsEqual(income.incomeType.name)
                        }.first ?? TypeValueRestModel()
                    }
                    
                    if(incomeTagSelected.name.isEmpty) {
                        incomeTagSelected = incomeViewModel.incomeTagList.filter { item in
                            item.name.elementsEqual(income.incomeTag.name)
                        }.first ?? TypeValueRestModel()
                    }
                    
                    if(amount.elementsEqual("0.0")) {
                        amount = income.amount.withCommas(decimalPlace: 2)
                    }
                    
                    if(taxPaid.elementsEqual("0.0")) {
                        taxPaid = income.taxPaid.withCommas(decimalPlace: 2)
                    }
                    
                    if(currencySelected.name.isEmpty) {
                        currencySelected = currencyList.filter {
                            $0.code.elementsEqual(income.currency)
                        }.first!
                    }
                    
                    if(Calendar.current.isDate(date, equalTo: Date().getEarliestDate(), toGranularity: .day)) {
//                        date = income.creditedDate
                    }
                }
            }
        }
    }
    
    private func allFieldsFilled () -> Bool {
        if !incomeTypeSelected.name.isEmpty && !incomeTagSelected.name.isEmpty && !currencySelected.name.isEmpty && !amount.isEmpty && !taxPaid.isEmpty {
            return true
        } else {
            return false
        }
    }
}
