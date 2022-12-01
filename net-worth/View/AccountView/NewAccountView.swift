//
//  NewAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI

struct NewAccountView: View {
    
    @State private var accountType: String = "None"
    @State private var symbolType: String = "None"
    @State private var accountName: String = ""
    
    @State private var financeModel = [FinanceModel]()
    @State private var financeSelected = FinanceModel()
    
    //Mutual fund and Stock fields
    @State private var totalShares: Double = 0.0
    @State private var currentRateShare: Double = 0.0
    @State private var symbol: String = ""
    
    @State private var currentBalance: Double = 0.0
    @State private var paymentReminder = false
    @State private var paymentDate = 1
    @State var dates = Array(1...31)
    
    @State var isPlus = true;
    @State private var showingAlert = false
    
    private var accountController = AccountController()
    private var financeController = FinanceController()
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchTerm: String = ""
    @StateObject private var financeListVM = FinanceListViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account detail") {
                    Picker(selection: $accountType, label: Text("Account Type")) {
                        ForEach(ConstantUtils.AccountType.allCases, id: \.rawValue) { accountType in
                            Text(accountType.rawValue).tag(accountType.rawValue)
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
                    else if(accountType == "Symbol") {
                        symbolPicker
                        
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
                        if(accountType != "Symbol") {
                            accountModel.currentBalance = currentBalance
                        }else {
                            accountModel.accountType = symbolType
                            accountModel.totalShares = totalShares
                            accountModel.symbol = symbol
                        }
                        accountModel.paymentReminder = paymentReminder
                        
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
            if accountName.isEmpty {
                return false
            } else {
                return true
            }
        }else if accountType == "Credit Card" {
            if accountName.isEmpty {
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
        }else if accountType == "Symbol" {
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
            TextField(labelName, value: $totalShares, formatter: Double().formatter())
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
            TextField("Current Balance", value: $currentBalance, formatter: Double().formatter())
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
    
    var symbolPicker: some View {
        Picker(selection: $financeSelected, label: Text("Symbol Name")) {
            SearchBar(text: $searchTerm, placeholder: "Search")
            ForEach(financeListVM.financeModels, id: \.self) { (data) in
                HStack {
                    VStack {
                        SymbolPickerLeftVerticalViewer(financeModel: data)
                    }
                    VStack {
                        SymbolPickerRightVerticalViewer(financeDetailModel: data.financeDetailModel!)
                    }
                }
                .tag(data)
            }
        }
        .onChange(of: searchTerm) { (data) in
            Task.init {
                if(!data.isEmpty) {
                    await financeListVM.getAllSymbols(searchTerm: data)
                } else {
                    financeListVM.financeModels.removeAll()
                }
            }
        }
        .onChange(of: financeSelected) { (data) in
            accountName = data.longname ?? data.shortname ?? " "
            symbolType = data.typeDisp ?? " "
            symbol = data.symbol ?? " "
            currentRateShare = data.financeDetailModel?.regularMarketPrice ?? 0.0
            
            currentBalance = totalShares * currentRateShare
        }
        .pickerStyle(.navigationLink)
    }
}

struct SymbolPickerLeftVerticalViewer: View {
    
    var financeModel: FinanceModel
    
    var body: some View {
        Text(financeModel.symbol!)
            .frame(maxWidth: .infinity, alignment: .leading)
        HStack {
            Text(financeModel.exchDisp!)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.gray)
            Text(financeModel.financeDetailModel?.currency ?? "")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.gray)
        }
        Text(financeModel.longname ?? financeModel.shortname ?? "")
            .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
            .foregroundColor(Color(red: 64/255, green: 64/255, blue: 64/255))
    }
}

struct SymbolPickerRightVerticalViewer: View {
    
    var financeDetailModel: FinanceDetailModel
    
    var body: some View {
        Text(financeDetailModel.regularMarketPrice?.withCommas() ?? "0.0")
            .frame(maxWidth: .infinity, alignment: .trailing)
        if(financeDetailModel.oneDayChange ?? 0 > 0) {
            Text("+" + (financeDetailModel.oneDayChange?.withCommas() ?? "0.0"))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.green)
        } else if(financeDetailModel.oneDayChange ?? 0 < 0) {
            Text(financeDetailModel.oneDayChange?.withCommas() ?? "0.0")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.red)
        }
    }
}

struct NewAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NewAccountView()
    }
}
