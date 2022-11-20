//
//  NewAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI

struct NewAccountView: View {
    
    @State var accountType: String = "None"
    @State var accountName: String = ""
    @State var currentBalance: String = "0.0"
    @State var paymentReminder = false
    
    @State private var paymentDate = 1
    @State var dates = Array(1...31)
    
    @State var isPlus = true;
    
    var accountTypes =  ["None", "Saving", "Credit Card", "Loan", "Stock", "Mutual Fund"]
    
    private var accountController = AccountController()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account detail") {
                    Picker(selection: $accountType, label: Text("Account Type")) {
                        ForEach(accountTypes, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .onChange(of: accountType) { _ in
                        accountName=""
                        currentBalance="0.0"
                        paymentDate = 1
                        paymentReminder = false
                    }
                    if accountType != "None" {
                        HStack {
                            Text("Account Name")
                            Spacer()
                            TextField("Account Name", text: $accountName)
                        }
                    }
                    if accountType != "None" {
                        HStack {
                            Text("Current Balance")
                            Spacer()
                            Button(action: currentBalanceButtonAction, label: {
                                Label("", systemImage: isPlus ? "minus" : "plus")
                            })
                            Spacer()
                            TextField("Current Balance", text: $currentBalance)
                                .keyboardType(.decimalPad)
                                .onChange(of: currentBalance, perform: { _ in
                                    currentBalanceOnChange()
                                })
                        }
                    }
                    if accountType == "Loan" || accountType == "Credit Card" {
                        Toggle("Enable Payment Reminder", isOn: $paymentReminder)
                    }
                    if paymentReminder {
                        Picker("Select a payment date", selection: $paymentDate) {
                            ForEach(dates, id: \.self) {
                                Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        accountController.addAccount(accountType: accountType, accountName: accountName, currentBalance: currentBalance, paymentReminder: paymentReminder, paymentDate: paymentDate)
                        dismiss()
                    }, label: {
                        Label("Add Account", systemImage: "checkmark")
                    }).disabled(!allFieldsFilled())
                }
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func allFieldsFilled () -> Bool {
        if accountType == "Saving" {
            if accountName.isEmpty || currentBalance.isEmpty {
                return false
            } else {
                return true
            }
        }else if accountType == "Credit Card" {
            if accountName.isEmpty || currentBalance.isEmpty {
                return false
            } else {
                return true
            }
        }else if accountType == "Loan" {
            if accountName.isEmpty || currentBalance.isEmpty {
                return false
            } else {
                return true
            }
        }else if accountType == "Stock" {
            if accountName.isEmpty || currentBalance.isEmpty {
                return false
            } else {
                return true
            }
        }else if accountType == "Mutual Fund" {
            if accountName.isEmpty || currentBalance.isEmpty {
                return false
            } else {
                return true
            }
        }else {
            return false
        }
    }
    
    private func currentBalanceButtonAction() {
        if isPlus {
            currentBalance = "-\(currentBalance)"
            isPlus = false
        }else {
            let value = Double((currentBalance as NSString).doubleValue) * -1
            currentBalance = "\(value)"
            isPlus = true
        }
    }
    
    private func currentBalanceOnChange() {
        let filtered = currentBalance.filter {"0123456789.".contains($0)}
        
        if filtered.contains(".") {
            let splitted = filtered.split(separator: ".")
            if splitted.count >= 2 {
                let preDecimal = String(splitted[0])
                if String(splitted[1]).count == 3 {
                    let afterDecimal = String(splitted[1]).prefix(splitted[1].count - 1)
                    if isPlus {
                        currentBalance = "\(preDecimal).\(afterDecimal)"
                    }else {
                        currentBalance = "-\(preDecimal).\(afterDecimal)"
                    }
                }else {
                    let afterDecimal = String(splitted[1])
                    if isPlus {
                        currentBalance = "\(preDecimal).\(afterDecimal)"
                    }else {
                        currentBalance = "-\(preDecimal).\(afterDecimal)"
                    }
                }
            }else if splitted.count == 1 {
                let preDecimal = String(splitted[0])
                if isPlus {
                    currentBalance = "\(preDecimal)."
                }else {
                    currentBalance = "-\(preDecimal)."
                }
            }else {
                if isPlus {
                    currentBalance = "0."
                }else {
                    currentBalance = "-0."
                }
            }
        } else if filtered.isEmpty && !currentBalance.isEmpty {
            currentBalance = ""
        } else if !filtered.isEmpty {
            currentBalance = filtered
        }
    }
}

struct NewAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NewAccountView()
    }
}
