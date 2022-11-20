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
    @State private var totalShares: String = ""
    @State private var currentRateShare: String = ""
    @State private var currentBalance: String = "0.00"
    @State private var paymentReminder = false
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
                        totalShares=""
                        currentRateShare=""
                        currentBalance="0.0"
                        paymentDate = 1
                        paymentReminder = false
                    }
                    if(accountType == "Saving") {
                        accountNameField()
                        currentBalanceField()
                    }
                    else if(accountType == "Credit Card") {
                        accountNameField()
                        currentBalanceField()
                        enablePaymentReminderField()
                        if(paymentReminder) {
                            paymentDateField()
                        }
                    }
                    else if(accountType == "Loan") {
                        
                    }
                    else if(accountType == "Stock") {
                        stockNameField()
                        totalSharesField()
                        currentRateStockField()
                        totalValueField()
                    }
                    else if(accountType == "Mutual Fund") {
                        mutualFundNameField()
                        totalUnitsField()
                        currentRateMutualFundField()
                        totalValueField()
                        enablePaymentReminderMutualFundField()
                        if(paymentReminder) {
                            paymentDateMutualFundField()
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
                        accountModel.currentRateShare = currentRateShare
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
    
    private func accountNameField() -> HStack<(TextField<Text>)> {
        return HStack {
            TextField("Account Name", text: $accountName)
        }
    }
    
    private func stockNameField() -> HStack<(TextField<Text>)> {
        return HStack {
            TextField("Stock Name", text: $accountName)
        }
    }
    
    private func mutualFundNameField() -> HStack<(TextField<Text>)> {
        return HStack {
            TextField("Mutual Fund Name", text: $accountName)
        }
    }
    
    private func totalSharesField() -> HStack<(some View)> {
        return HStack {
            TextField("Total Shares", text: $totalShares)
                .keyboardType(.decimalPad)
                .onChange(of: totalShares, perform: { _ in
                    let filtered = totalShares.filter {"0123456789.".contains($0)}
                    
                    if filtered.contains(".") {
                        let splitted = filtered.split(separator: ".")
                        if splitted.count >= 2 {
                            let preDecimal = String(splitted[0])
                            if String(splitted[1]).count == 3 {
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
    
    private func totalUnitsField() -> HStack<(some View)> {
        return HStack {
            TextField("Total Units", text: $totalShares)
                .keyboardType(.decimalPad)
                .onChange(of: totalShares, perform: { _ in
                    let filtered = totalShares.filter {"0123456789.".contains($0)}
                    
                    if filtered.contains(".") {
                        let splitted = filtered.split(separator: ".")
                        if splitted.count >= 2 {
                            let preDecimal = String(splitted[0])
                            if String(splitted[1]).count == 3 {
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
    
    private func currentRateStockField() -> HStack<(some View)> {
        return HStack {
            TextField("Current rate of a share", text: $currentRateShare)
                .keyboardType(.decimalPad)
                .onChange(of: currentRateShare, perform: { _ in
                    let filtered = currentRateShare.filter {"0123456789.".contains($0)}
                    
                    if filtered.contains(".") {
                        let splitted = filtered.split(separator: ".")
                        if splitted.count >= 2 {
                            let preDecimal = String(splitted[0])
                            if String(splitted[1]).count == 3 {
                                let afterDecimal = String(splitted[1]).prefix(splitted[1].count - 1)
                                currentRateShare = "\(preDecimal).\(afterDecimal)"
                            }else {
                                let afterDecimal = String(splitted[1])
                                currentRateShare = "\(preDecimal).\(afterDecimal)"
                            }
                        }else if splitted.count == 1 {
                            let preDecimal = String(splitted[0])
                            currentRateShare = "\(preDecimal)."
                        }else {
                            currentRateShare = "0."
                        }
                    } else if filtered.isEmpty && !currentRateShare.isEmpty {
                        currentRateShare = ""
                    } else if !filtered.isEmpty {
                        currentRateShare = filtered
                    }
                    
                    let totalShares = Double((totalShares as NSString).doubleValue)
                    let currentRateShare = Double((currentRateShare as NSString).doubleValue)
                    currentBalance = String(totalShares * currentRateShare)
                })
        }
    }
    
    private func currentRateMutualFundField() -> HStack<(some View)> {
        return HStack {
            TextField("Current rate of a unit", text: $currentRateShare)
                .keyboardType(.decimalPad)
                .onChange(of: currentRateShare, perform: { _ in
                    let filtered = currentRateShare.filter {"0123456789.".contains($0)}
                    
                    if filtered.contains(".") {
                        let splitted = filtered.split(separator: ".")
                        if splitted.count >= 2 {
                            let preDecimal = String(splitted[0])
                            if String(splitted[1]).count == 3 {
                                let afterDecimal = String(splitted[1]).prefix(splitted[1].count - 1)
                                currentRateShare = "\(preDecimal).\(afterDecimal)"
                            }else {
                                let afterDecimal = String(splitted[1])
                                currentRateShare = "\(preDecimal).\(afterDecimal)"
                            }
                        }else if splitted.count == 1 {
                            let preDecimal = String(splitted[0])
                            currentRateShare = "\(preDecimal)."
                        }else {
                            currentRateShare = "0."
                        }
                    } else if filtered.isEmpty && !currentRateShare.isEmpty {
                        currentRateShare = ""
                    } else if !filtered.isEmpty {
                        currentRateShare = filtered
                    }
                    
                    let totalShares = Double((totalShares as NSString).doubleValue)
                    let currentRateShare = Double((currentRateShare as NSString).doubleValue)
                    currentBalance = String(totalShares * currentRateShare)
                })
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
                })
        }
    }
    
    private func enablePaymentReminderField() -> Toggle<Text> {
        return Toggle("Enable Payment Reminder", isOn: $paymentReminder)
    }
    
    private func enablePaymentReminderMutualFundField() -> Toggle<Text> {
        return Toggle("Enable SIP Reminder", isOn: $paymentReminder)
    }
    
    private func paymentDateField() -> Picker<Text, Int, ForEach<[Int], Int, some View>> {
        return Picker("Select a payment date", selection: $paymentDate) {
            ForEach(dates, id: \.self) {
                Text("\($0.formatted(.number.grouping(.never)))").tag($0)
            }
        }
    }
    
    private func paymentDateMutualFundField() -> Picker<Text, Int, ForEach<[Int], Int, some View>> {
        return Picker("Select a SIP date", selection: $paymentDate) {
            ForEach(dates, id: \.self) {
                Text("\($0.formatted(.number.grouping(.never)))").tag($0)
            }
        }
    }
}

struct NewAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NewAccountView()
    }
}
