//
//  NewAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI

struct NewAccountView: View {
    
    @State private var accountType: String = "None"
    @State private var accountName: String = ""
    
    @State private var mutualFundField: Mutualfund = Mutualfund()
    
    //Mutual fund and Stock fields
    @State private var totalShares: String = ""
    @State private var currentRateShare: String = ""
    
    @State private var currentBalance: String = "0.00"
    @State private var paymentReminder = false
    @State private var paymentDate = 1
    @State private var total = ""
    @State private var monthlyInstallation = ""
    @State var dates = Array(1...31)
    
    @State var isPlus = true;
    
    var accountTypes =  ["None", "Saving", "Credit Card", "Loan", "Stock", "Mutual Fund"]
    
    private var accountController = AccountController()
    
    @Environment(\.dismiss) var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Mutualfund.name, ascending: true)],
        animation: .default)
    private var mutualfunds: FetchedResults<Mutualfund>
    
    @State private var searchTerm: String = ""
    
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
                        totalShares=""
                        currentRateShare=""
                        currentBalance="0.0"
                        paymentDate = 1
                        paymentReminder = false
                    }
                    if(accountType == "Saving") {
                        nameField(labelName: "Account Name")
                        currentBalanceField()
                    }
                    else if(accountType == "Credit Card") {
                        nameField(labelName: "Credit Card Name")
                        currentBalanceField()
                        enablePaymentReminderField(labelName: "Enable Payment Reminder")
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a payment date")
                        }
                    }
                    else if(accountType == "Loan") {
                        nameField(labelName: "Loan Name")
                        currentBalanceField()
                        enablePaymentReminderField(labelName: "Enable Loan Payment Reminder")
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a payment date")
                        }
                    }
                    else if(accountType == "Stock") {
                        nameField(labelName: "Stock Name")
                        totalField(labelName: "Total Shares")
                        currentRateField(labelName: "Current rate of a share")
                        totalValueField()
                    }
                    else if(accountType == "Mutual Fund") {
                        Picker(selection: $mutualFundField, label: Text("Mutual Fund Name")) {
                            SearchBar(text: $searchTerm, placeholder: "Search Mutual Funds")
                            ForEach(filteredMF) { mf in
                                Text(mf.name ?? "").tag(mf)
                            }
                        }.onChange(of: mutualFundField) { (data) in
                            accountName = data.name!
                            currentRateShare = data.rate!
                        }.pickerStyle(.navigationLink)
                        
                        totalField(labelName: "Total Units")
                        currentRateField(labelName: "Current rate of a unit")
                        totalValueField()
                        enablePaymentReminderField(labelName: "Enable SIP Reminder")
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a SIP date")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        let accountModel = AccountModel()
                        accountModel.accountType = accountType
                        accountModel.accountName = accountName
                        accountModel.currentBalance = currentBalance
                        accountModel.paymentReminder = paymentReminder
                        
                        //Mutual fund and Stock fields
                        accountModel.totalShares = totalShares
                        
                        if(paymentReminder) {
                            accountModel.paymentDate = paymentDate
                        }
                        accountController.addAccount(accountModel: accountModel)
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
            if accountName.isEmpty || totalShares.isEmpty || currentRateShare.isEmpty || currentBalance.isEmpty {
                return false
            } else {
                return true
            }
        }else if accountType == "Mutual Fund" {
            if accountName.isEmpty || totalShares.isEmpty || currentRateShare.isEmpty || currentBalance.isEmpty {
                return false
            } else {
                return true
            }
        }else {
            return false
        }
    }
    
    private func nameField(labelName: String) -> HStack<(TextField<Text>)> {
        return HStack {
            TextField(labelName, text: $accountName)
        }
    }
    
    private func totalField(labelName: String) -> HStack<(some View)> {
        return HStack {
            TextField(labelName, text: $totalShares)
                .keyboardType(.decimalPad)
                .onChange(of: totalShares, perform: { _ in
                    let filtered = totalShares.filter {"0123456789.".contains($0)}
                    
                    if filtered.contains(".") {
                        let splitted = filtered.split(separator: ".")
                        if splitted.count >= 2 {
                            let preDecimal = String(splitted[0])
                            if String(splitted[1]).count == 5 {
                                let afterDecimal = String(splitted[1]).prefix(splitted[1].count - 1)
                                totalShares = "\(preDecimal).\(afterDecimal)"
                            }else {
                                let afterDecimal = String(splitted[1])
                                totalShares = "\(preDecimal).\(afterDecimal)"
                            }
                        }else if splitted.count == 1 {
                            let preDecimal = String(splitted[0])
                            totalShares = "\(preDecimal)."
                        }else {
                            totalShares = "0."
                        }
                    } else if filtered.isEmpty && !totalShares.isEmpty {
                        totalShares = ""
                    } else if !filtered.isEmpty {
                        totalShares = filtered
                    }
                    
                    let totalShares = Double((totalShares as NSString).doubleValue)
                    let currentRateShare = Double((currentRateShare as NSString).doubleValue)
                    currentBalance = String(totalShares * currentRateShare)
                })
        }
    }
    
    private func currentRateField(labelName: String) -> HStack<(some View)> {
        return HStack {
            Text(labelName)
            Spacer()
            Text(currentRateShare)
        }
    }
    
    private func totalValueField() -> HStack<TupleView<(Text, Spacer, Text)>> {
        return HStack {
            Text("Total Value")
            Spacer()
            Text(currentBalance)
        }
    }
    
    private func currentBalanceField() -> HStack<TupleView<(Text, Spacer, Button<Label<Text, Image>>, Spacer, some View)>> {
        return HStack {
            Text("Current Balance")
            Spacer()
            Button(action: {
                if isPlus {
                    currentBalance = "-\(currentBalance)"
                    isPlus = false
                }else {
                    let value = Double((currentBalance as NSString).doubleValue) * -1
                    currentBalance = "\(value)"
                    isPlus = true
                }
            }, label: {
                Label("", systemImage: isPlus ? "minus" : "plus")
            })
            Spacer()
            TextField("Current Balance", text: $currentBalance)
                .keyboardType(.decimalPad)
                .onChange(of: currentBalance, perform: { _ in
                    let filtered = currentBalance.filter {"0123456789.".contains($0)}
                    
                    if filtered.contains(".") {
                        let splitted = filtered.split(separator: ".")
                        if splitted.count >= 2 {
                            let preDecimal = String(splitted[0])
                            if String(splitted[1]).count == 5 {
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
                })
        }
    }
    
    private func enablePaymentReminderField(labelName: String) -> Toggle<Text> {
        return Toggle(labelName, isOn: $paymentReminder)
    }
    
    private func paymentDateField(labelName: String) -> Picker<Text, Int, ForEach<[Int], Int, some View>> {
        return Picker(labelName, selection: $paymentDate) {
            ForEach(dates, id: \.self) {
                Text("\($0.formatted(.number.grouping(.never)))").tag($0)
            }
        }
    }
    
    var filteredMF: [Mutualfund] {
        mutualfunds.filter { mf in
            if(searchTerm.isEmpty) {
                return true
            } else {
                return mf.name!.lowercased().contains(searchTerm.lowercased())
            }
        }
    }
}

struct NewAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NewAccountView()
    }
}
