//
//  NewAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI

struct NewAccountView: View {
    
    @State var accountType: String
    @State var symbolType: String = "None"
    @State var accountName: String = ""
    @State var currenySelected: Currency = Currency()
    var currencyList = CurrencyList().currencyList
    @State  var filterCurrencyList = CurrencyList().currencyList
    @State  var currencyChanged = false
    
    @State  var financeModel = [FinanceModel]()
    @State  var financeSelected = FinanceModel()
    
    //Mutual fund and Stock fields
    @State  var totalShares: Double = 0.0
    @State  var currentRateShare: Double = 0.0
    @State  var symbol: String = ""
    
    @State  var currentBalance: Double = 0.0
    @State  var paymentReminder = false
    @State  var paymentDate = 1
    @State var dates = Array(1...28)
    
    @State var isPlus = true
    
    var accountController = AccountController()
    var financeController = FinanceController()
    
    @Environment(\.dismiss) var dismiss
    
    @State var searchTerm: String = ""
    @StateObject var financeListVM = FinanceListViewModel()
    
    @ObservedObject var accountViewModel : AccountViewModel
    
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
                        currenySelected = SettingsController().getDefaultCurrency()
                    }
                    if(accountType == "Saving") {
                        nameField(labelName: "Account Name")
                        currentBalanceField()
                        currencyPicker
                    }
                    else if(accountType == "Credit Card") {
                        nameField(labelName: "Credit Card Name")
                        currentBalanceField()
                        currencyPicker
                        enablePaymentReminderField(labelName: "Enable Payment Reminder")
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a payment date")
                        }
                    }
                    else if(accountType == "Loan") {
                        nameField(labelName: "Loan Name")
                        currentBalanceField()
                        currencyPicker
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
                    } else if(accountType == "Other") {
                        nameField(labelName: "Account Name")
                        currentBalanceField()
                        currencyPicker
                        enablePaymentReminderField(labelName: "Enable Payment Reminder")
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a payment date")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        var newAccount = Account()
                        newAccount.accountType = accountType
                        newAccount.accountName = accountName
                        if(accountType != "Symbol") {
                            newAccount.currentBalance = isPlus ? currentBalance : currentBalance * -1
                            newAccount.currency = currenySelected.code
                        }else {
                            newAccount.accountType = symbolType
                            newAccount.totalShares = totalShares
                            newAccount.symbol = symbol
                            newAccount.currency = financeSelected.financeDetailModel?.currency ?? ""
                        }
                        newAccount.paymentReminder = paymentReminder
                        
                        if(paymentReminder) {
                            newAccount.paymentDate = paymentDate
                        }
                        accountController.addAccount(newAccount: newAccount)
                        Task.init {
                            await accountViewModel.getAccountList()
                            await accountViewModel.getTotalBalance()
                        }
                        dismiss()
                    }, label: {
                        Label("Add Account", systemImage: "checkmark")
                    })
                    .disabled(!allFieldsFilled())
                }
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func allFieldsFilled () -> Bool {
        if accountType == "Saving" {
            if accountName.isEmpty || currenySelected.name.isEmpty {
                return false
            } else {
                return true
            }
        }else if accountType == "Credit Card" {
            if accountName.isEmpty || currenySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        }else if accountType == "Loan" {
            if accountName.isEmpty || currentBalance.isZero || currenySelected.name.isEmpty  {
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
        }else if accountType == "Other" {
            if accountName.isEmpty || currenySelected.name.isEmpty  {
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
                .onChange(of: [totalShares, currentRateShare], perform: { _ in
                    currentBalance = totalShares * currentRateShare
                })
        }
    }
    
    private func currentRateField(labelName: String) -> HStack<TupleView<(Text, Spacer, some View)>> {
        return HStack {
            Text(labelName)
            Spacer()
            Text("\(currentRateShare.withCommas(decimalPlace: 4))")
                .onChange(of: [totalShares, currentRateShare], perform: { _ in
                    currentBalance = totalShares * currentRateShare
                })
        }
    }
    
    private func totalValueField() -> HStack<TupleView<(Text, Spacer, some View)>> {
        return HStack {
            Text("Total Value")
            Spacer()
            Text("\(currentBalance.withCommas(decimalPlace: 2))")
                .onChange(of: [totalShares, currentRateShare], perform: { _ in
                    currentBalance = totalShares * currentRateShare
                })
        }
    }
    
    private func currentBalanceField() -> HStack<TupleView<(Text, Spacer, Button<Label<Text, Image>>, Spacer, some View)>> {
        return HStack {
            Text("Current Balance")
            Spacer()
            Button(action: {
                if isPlus {
                    isPlus = false
                }else {
                    isPlus = true
                }
            }, label: {
                Label("", systemImage: isPlus ? "plus" : "minus")
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
        Picker("", selection: $financeSelected) {
            SearchBar(text: $searchTerm, placeholder: "Search MutualFund,Stocks,ETF,Crypto")
            ForEach(financeListVM.financeModels, id: \.self) { (data) in
                HStack {
                    VStack {
                        SymbolPickerLeftVerticalViewer(financeModel: data)
                    }
                    VStack {
                        SymbolPickerRightVerticalViewer(financeDetailModel: data.financeDetailModel ?? FinanceDetailModel())
                    }
                }
                .tag(data)
            }
        }
        .edgesIgnoringSafeArea(.all)
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
            symbolType = data.quoteType ?? " "
            symbol = data.symbol ?? " "
            currentRateShare = data.financeDetailModel?.regularMarketPrice ?? 0.0
            
            currentBalance = totalShares * currentRateShare
        }
        .pickerStyle(.inline)
    }
}

struct SymbolPickerLeftVerticalViewer: View {
    
    var financeModel: FinanceModel
    
    var body: some View {
        Text(financeModel.symbol!)
            .frame(maxWidth: .infinity, alignment: .leading)
        Text(financeModel.longname ?? financeModel.shortname ?? "").font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(.gray)
        HStack {
            Text(financeModel.exchDisp!).font(.system(size: 11))
                .frame(idealWidth: .infinity, alignment: .leading)
                .foregroundColor(Color(red: 96/255, green: 96/255, blue: 96/255))
            Text(financeModel.financeDetailModel?.currency ?? "").font(.system(size: 11))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(Color(red: 96/255, green: 96/255, blue: 96/255))
        }
        Text(financeModel.quoteType!).font(.system(size: 10))
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color(red: 96/255, green: 96/255, blue: 96/255))
    }
}

struct SymbolPickerRightVerticalViewer: View {
    
    var financeDetailModel: FinanceDetailModel
    
    @State private var valueType = ValueType.literal
    
    var body: some View {
        Text((CurrencyList().getSymbolWithCode(code: financeDetailModel.symbol ?? "").symbol) + " " + (financeDetailModel.regularMarketPrice?.withCommas(decimalPlace: 4) ?? "0.0"))
            .frame(maxWidth: .infinity, alignment: .trailing)
        if(valueType == ValueType.literal) {
            if(financeDetailModel.oneDayChange ?? 0 > 0) {
                Button("+" + (financeDetailModel.oneDayChange?.withCommas(decimalPlace: 2) ?? "0.0")) {
                    valueType = .percentage
                }
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.green)
            } else if(financeDetailModel.oneDayChange ?? 0 < 0) {
                Button(financeDetailModel.oneDayChange?.withCommas(decimalPlace: 2) ?? "0.0") {
                    valueType = .percentage
                }
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.red)
            }
        } else {
            if(financeDetailModel.oneDayPercentChange ?? 0 > 0) {
                Button("+" + (financeDetailModel.oneDayPercentChange?.withCommas(decimalPlace: 2) ?? "0.0") + "%") {
                    valueType = .literal
                }
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.green)
            } else if(financeDetailModel.oneDayPercentChange ?? 0 < 0) {
                Button((financeDetailModel.oneDayPercentChange?.withCommas(decimalPlace: 2) ?? "0.0") + "%") {
                    valueType = .literal
                }
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.red)
            }
        }
    }
}
