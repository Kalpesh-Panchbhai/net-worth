//
//  NewAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI

struct NewAccountView: View {
    
    @State var accountType: String
    @State var loanType: String = "Consumer"
    @State var symbolType: String = "None"
    @State var accountName: String = ""
    @State var currenySelected: Currency = Currency()
    var currencyList = CurrencyList().currencyList
    @State  var filterCurrencyList = CurrencyList().currencyList
    @State  var currencyChanged = false
    
    @State  var financeModel = [FinanceModel]()
    @State  var financeSelected = FinanceModel()
    
    @State  var currentBalance: Double = 0.0
    @State  var monthlyEmi: Double = 0.0
    @State  var paymentReminder = false
    @State  var paymentDate = 1
    @State  var loanPaymentDate = 1
    @State var dates = Array(1...28)
    @State private var accountOpenedDate = Date()
    
    @State var isPlus = true
    
    var accountController = AccountController()
    var financeController = FinanceController()
    var watchController = WatchController()
    
    @Environment(\.dismiss) var dismiss
    
    @State var searchTerm: String = ""
    @StateObject var watchViewModel = WatchViewModel()
    
    @ObservedObject var accountViewModel : AccountViewModel
    @State private var selectedWatchList = Watch()
    
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
                        currentBalance = 0.0
                        paymentDate = 1
                        paymentReminder = false
                        currenySelected = SettingsController().getDefaultCurrency()
                        selectedWatchList = Watch()
                    }
                    if(accountType == "Saving") {
                        nameField(labelName: "Account Name")
                        currentBalanceField()
                        currencyPicker
                        watchListPicker
                        accountOpenedDatePicker
                    }
                    else if(accountType == "Credit Card") {
                        nameField(labelName: "Credit Card Name")
                        currentBalanceField()
                        currencyPicker
                        enablePaymentReminderField(labelName: "Enable Payment Reminder")
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a payment date")
                        }
                        watchListPicker
                        accountOpenedDatePicker
                    }
                    else if(accountType == "Loan") {
                        Picker(selection: $loanType, label: Text("Loan Type")) {
                            Text("Consumer").tag("Consumer")
                            Text("Non Consumer").tag("Non Consumer")
                        }
                        nameField(labelName: "Loan Name")
                        currentBalanceField()
                        if(loanType.elementsEqual("Consumer")) {
                            monthlyEMIField()
                            loanPaymentDateField(labelName: "Select a loan payment date")
                        }
                        currencyPicker
                        enablePaymentReminderField(labelName: "Enable Loan Payment Reminder")
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a payment date")
                        }
                        watchListPicker
                        accountOpenedDatePicker
                    } else if(accountType == "Other") {
                        nameField(labelName: "Account Name")
                        currentBalanceField()
                        currencyPicker
                        enablePaymentReminderField(labelName: "Enable Payment Reminder")
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a payment date")
                        }
                        watchListPicker
                        accountOpenedDatePicker
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        var newAccount = Account()
                        newAccount.accountType = accountType
                        if(accountType.elementsEqual("Loan")) {
                            newAccount.loanType = loanType
                        }
                        newAccount.accountName = accountName
                        newAccount.currentBalance = isPlus ? currentBalance : currentBalance * -1
                        newAccount.currency = currenySelected.code
                        newAccount.paymentReminder = paymentReminder
                        
                        if(paymentReminder) {
                            newAccount.paymentDate = paymentDate
                        }
                        Task.init {
                            let accountID = await accountController.addAccount(newAccount: newAccount, accountOpenedDate: accountOpenedDate)
                            newAccount.id = accountID
                            if(selectedWatchList.id != "") {
                                selectedWatchList.accountID.append(accountID)
                                watchController.addAccountToWatchList(watch: selectedWatchList)
                            }
                            var watch = try await watchController.getDefaultWatchList()
                            watch.accountID.append(accountID)
                            watchController.addAccountToWatchList(watch: watch)
                            await accountViewModel.getAccountList()
                            await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                            accountController.addLoanAccountEMITransaction(account: newAccount, emiDate: loanPaymentDate, accountOpenedDate: accountOpenedDate, monthlyEmiAmount: monthlyEmi)
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
        .onAppear {
            Task.init {
                await watchViewModel.getAllWatchList()
            }
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
    
    var watchListPicker: some View {
        Picker(selection: $selectedWatchList, label: Text("Watch List")) {
            Text("Select").tag(Watch())
            ForEach(watchViewModel.watchList, id: \.self) { data in
                if(data.accountName != "All") {
                    Text(data.accountName).tag(data)
                }
            }
        }
    }
    
    var accountOpenedDatePicker: some View {
        DatePicker("Opened date", selection: $accountOpenedDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
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
    
    private func monthlyEMIField() -> HStack<TupleView<(Text, Spacer, some View)>> {
        return HStack {
            Text("Monthly EMI")
            Spacer()
            TextField("Monthly EMI", value: $monthlyEmi, formatter: Double().formatter())
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
    
    private func loanPaymentDateField(labelName: String) -> Picker<Text, Int, ForEach<[Int], Int, some View>> {
        return Picker(labelName, selection: $loanPaymentDate) {
            ForEach(dates, id: \.self) {
                Text("\($0.formatted(.number.grouping(.never)))").tag($0)
            }
        }
    }
    
}
