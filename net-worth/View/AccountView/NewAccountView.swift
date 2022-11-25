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
    @State private var totalShares: Double = 0.0
    @State private var currentRateShare: Double = 0.0
    
    @State private var currentBalance: Double = 0.0
    @State private var paymentReminder = false
    @State private var paymentDate = 1
    @State var dates = Array(1...31)
    
    @State var isPlus = true;
    @State private var showingAlert = false
    
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
                        totalShares = 0.0
                        currentRateShare = 0.0
                        currentBalance = 0.0
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
                            currentRateShare = data.rate
                            
                            currentBalance = totalShares * currentRateShare
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
                        if(accountType != "Mutual Fund") {
                            accountModel.currentBalance = currentBalance
                        }
                        accountModel.paymentReminder = paymentReminder
                        
                        //Mutual fund and Stock fields
                        accountModel.totalShares = totalShares
                        
                        if(paymentReminder) {
                            accountModel.paymentDate = paymentDate
                        }
                        accountController.addAccount(accountModel: accountModel)
                        showingAlert = true
                    }, label: {
                        Label("Add Account", systemImage: "checkmark")
                    })
                    .disabled(!allFieldsFilled())
                    .alert("New " + accountType + " account has been added!", isPresented: $showingAlert, actions: {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    }, message: {
                        Text("Account Name : " + accountName)
                    })
                }
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func allFieldsFilled () -> Bool {
        if accountType == "Saving" {
            if accountName.isEmpty || currentBalance.isZero {
                return false
            } else {
                return true
            }
        }else if accountType == "Credit Card" {
            if accountName.isEmpty || currentBalance.isZero {
                return false
            } else {
                return true
            }
        }else if accountType == "Loan" {
            if accountName.isEmpty || currentBalance.isZero {
                return false
            } else {
                return true
            }
        }else if accountType == "Stock" {
            if accountName.isEmpty || totalShares.isZero || currentRateShare.isZero {
                return false
            } else {
                return true
            }
        }else if accountType == "Mutual Fund" {
            if accountName.isEmpty || totalShares.isZero || currentRateShare.isZero {
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
            TextField(labelName, value: $totalShares, formatter: formatter)
                .keyboardType(.decimalPad)
                .onChange(of: totalShares, perform: { _ in
                    currentBalance = totalShares * currentRateShare
                })
        }
    }
    
    private func currentRateField(labelName: String) -> HStack<(some View)> {
        return HStack {
            Text(labelName)
            Spacer()
            Text("\(currentRateShare.withCommas())")
        }
    }
    
    private func totalValueField() -> HStack<TupleView<(Text, Spacer, Text)>> {
        return HStack {
            Text("Total Value")
            Spacer()
            Text("\(currentBalance.withCommas())")
        }
    }
    
    private func currentBalanceField() -> HStack<TupleView<(Text, Spacer, Button<Label<Text, Image>>, Spacer, some View)>> {
        return HStack {
            Text("Current Balance")
            Spacer()
            Button(action: {
                if isPlus {
                    currentBalance = currentBalance * -1
                    isPlus = false
                }else {
                    currentBalance = currentBalance * -1
                    isPlus = true
                }
            }, label: {
                Label("", systemImage: isPlus ? "minus" : "plus")
            })
            Spacer()
            TextField("Current Balance", value: $currentBalance, formatter: formatter)
                .keyboardType(.decimalPad)
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
    
    let formatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.roundingMode = .halfUp
        numberFormatter.maximumFractionDigits =  4
        return numberFormatter
    }()
}

struct NewAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NewAccountView()
    }
}
