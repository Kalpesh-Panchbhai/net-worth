//
//  NewIncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI

struct NewIncomeView: View {
    
    @State private var amount: String = "0.0"
    @State private var incomeType: String = "None"
    @State private var date = Date()
    
    var incomeTypes =  ["None", "Salary", "Portfolio","Other"]
    
    @Environment(\.dismiss) var dismiss
    
    private var incomeController = IncomeController()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Income detail") {
                    Picker(selection: $incomeType, label: Text("Income Type")) {
                        ForEach(incomeTypes, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .onChange(of: incomeType) { _ in
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
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        incomeController.addIncome(incometype: incomeType, amount: amount, date: date)
                        dismiss()
                    }, label: {
                        Label("Add Income", systemImage: "checkmark")
                    }).disabled(!allFieldsFilled())
                }
            }
            .navigationTitle("New Income")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func allFieldsFilled () -> Bool {
        if incomeType == "Salary" || incomeType == "Portfolio" || incomeType == "Other" {
            if amount.isEmpty {
                return false
            } else {
                return true
            }
        }else {
            return false
        }
    }
}

struct NewIncomeView_Previews: PreviewProvider {
    static var previews: some View {
        NewIncomeView()
    }
}