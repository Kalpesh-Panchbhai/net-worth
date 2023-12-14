//
//  NewAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI

struct NewAccountView: View {
    
    var currencyList = CurrencyList().currencyList
    var accountController = AccountController()
    var accountTransactionController = AccountTransactionController()
    var financeController = FinanceController()
    var watchController = WatchController()
    
    @State var scenePhaseBlur = 0
    @State var accountType: String
    @State var loanType: String = "Consumer"
    @State var symbolType: String = "None"
    @State var accountName: String = ""
    @State var currencySelected: Currency = Currency()
    @State var filterCurrencyList = CurrencyList().currencyList
    @State var currencyChanged = false
    @State var currentBalance: String = "0.0"
    @State var monthlyEmi: Double = 0.0
    @State var paymentReminder = false
    @State var paymentDate = 1
    @State var loanPaymentDate = 1
    @State var dates = Array(1...28)
    @State var accountOpenedDate = Date()
    @State var isPlus = true
    @State var searchTerm: String = ""
    @State var selectedWatchList = Watch()
    
    @StateObject var watchViewModel = WatchViewModel()
    @ObservedObject var accountViewModel : AccountViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account detail") {
                    Picker(selection: $accountType, label: Text("Account Type")) {
                        ForEach(ConstantUtils.AccountType.allCases, id: \.rawValue) { accountType in
                            Text(accountType.rawValue).tag(accountType.rawValue)
                        }
                    }
                    .foregroundColor(Color.theme.primaryText)
                    .onChange(of: accountType) { _ in
                        accountName=""
                        currentBalance = "0.0"
                        paymentDate = 1
                        paymentReminder = false
                        currencySelected = SettingsController().getDefaultCurrency()
                        selectedWatchList = Watch()
                        isPlus = true
                        loanPaymentDate = 1
                        monthlyEmi = 0.0
                        accountOpenedDate = Date()
                    }
                    if(accountType == "Saving") {
                        nameField(labelName: "Account Name")
                            .foregroundColor(Color.theme.primaryText)
                        currentBalanceField
                            .foregroundColor(Color.theme.primaryText)
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
                        watchListPicker
                        accountOpenedDatePicker
                    }
                    else if(accountType == "Credit Card") {
                        nameField(labelName: "Credit Card Name")
                            .foregroundColor(Color.theme.primaryText)
                        currentBalanceField
                            .foregroundColor(Color.theme.primaryText)
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
                        enablePaymentReminderField(labelName: "Enable Payment Reminder")
                            .foregroundColor(Color.theme.primaryText)
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a payment date")
                                .foregroundColor(Color.theme.primaryText)
                        }
                        watchListPicker
                        accountOpenedDatePicker
                    }
                    else if(accountType == "Loan") {
                        Picker(selection: $loanType, label: Text("Loan Type")) {
                            Text("Consumer").tag("Consumer")
                            Text("Non Consumer").tag("Non Consumer")
                        }
                        .foregroundColor(Color.theme.primaryText)
                        
                        nameField(labelName: "Loan Name")
                            .foregroundColor(Color.theme.primaryText)
                        currentBalanceField
                            .foregroundColor(Color.theme.primaryText)
                        if(loanType.elementsEqual("Consumer")) {
                            monthlyEMIField
                                .foregroundColor(Color.theme.primaryText)
                            loanPaymentDateField(labelName: "Loan payment date")
                                .foregroundColor(Color.theme.primaryText)
                        }
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
                        enablePaymentReminderField(labelName: "Enable Loan Payment Reminder")
                            .foregroundColor(Color.theme.primaryText)
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a payment date")
                                .foregroundColor(Color.theme.primaryText)
                        }
                        watchListPicker
                        accountOpenedDatePicker
                    } else if(accountType == "Broker") {
                        nameField(labelName: "Broker Name")
                            .foregroundColor(Color.theme.primaryText)
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
                        watchListPicker
                    } else if(accountType == "Other") {
                        nameField(labelName: "Account Name")
                            .foregroundColor(Color.theme.primaryText)
                        currentBalanceField
                            .foregroundColor(Color.theme.primaryText)
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
                        enablePaymentReminderField(labelName: "Enable Payment Reminder")
                            .foregroundColor(Color.theme.primaryText)
                        if(paymentReminder) {
                            paymentDateField(labelName: "Select a payment date")
                                .foregroundColor(Color.theme.primaryText)
                        }
                        watchListPicker
                        accountOpenedDatePicker
                    }
                }
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
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
                        newAccount.currentBalance = isPlus ? currentBalance.toDouble()! : currentBalance.toDouble()! * -1
                        newAccount.currency = currencySelected.code
                        newAccount.paymentReminder = paymentReminder
                        
                        if(paymentReminder) {
                            newAccount.paymentDate = paymentDate
                        }
                        Task.init {
                            let accountID = await accountController.addAccount(newAccount: newAccount, accountOpenedDate: accountOpenedDate)
                            newAccount.id = accountID
                            await accountViewModel.getAccountList()
                            if(selectedWatchList.id != "") {
                                selectedWatchList.accountID.append(accountID)
                                selectedWatchList.accountID.sort(by: { item1, item2 in
                                    accountViewModel.accountList.filter { account1 in
                                        account1.id!.elementsEqual(item1)
                                    }.first!.accountName <= accountViewModel.accountList.filter { account2 in
                                        account2.id!.elementsEqual(item2)
                                    }.first!.accountName
                                })
                                watchController.addAccountToWatchList(watch: selectedWatchList)
                            }
                            var watch = await watchController.getDefaultWatchList()
                            watch.accountID.append(accountID)
                            watch.accountID.sort(by: { item1, item2 in
                                accountViewModel.accountList.filter { account1 in
                                    account1.id!.elementsEqual(item1)
                                }.first!.accountName <= accountViewModel.accountList.filter { account2 in
                                    account2.id!.elementsEqual(item2)
                                }.first!.accountName
                            })
                            watchController.addAccountToWatchList(watch: watch)
                            await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                            if(accountType.elementsEqual("Loan") && loanType.elementsEqual("Consumer")) {
                                Task.init {
                                    await accountTransactionController.addLoanAccountEMITransaction(account: newAccount, emiDate: loanPaymentDate, accountOpenedDate: accountOpenedDate, monthlyEmiAmount: monthlyEmi)
                                }
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
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
        }
        .blur(radius: CGFloat(scenePhaseBlur))
        .onChange(of: scenePhase, perform: { value in
            if(value == .active) {
                scenePhaseBlur = 0
            } else {
                scenePhaseBlur = 5
            }
        })
        .onAppear {
            Task.init {
                await watchViewModel.getAllWatchList()
            }
        }
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
        .foregroundColor(Color.theme.primaryText)
    }
    
    var accountOpenedDatePicker: some View {
        DatePicker("Opened date", selection: $accountOpenedDate, in: ...Date(), displayedComponents: [.date])
            .foregroundColor(Color.theme.primaryText)
    }
    
    private func allFieldsFilled () -> Bool {
        if accountType == "Saving" {
            if accountName.isEmpty || currencySelected.name.isEmpty {
                return false
            } else {
                return true
            }
        } else if accountType == "Credit Card" {
            if accountName.isEmpty || currencySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        } else if accountType == "Loan" {
            if accountName.isEmpty || currentBalance.isEmpty || currencySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        } else if accountType == "Broker" {
            if accountName.isEmpty || currencySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        } else if accountType == "Other" {
            if accountName.isEmpty || currencySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
    
    private func nameField(labelName: String) -> HStack<(TextField<Text>)> {
        return HStack {
            TextField(labelName, text: $accountName)
        }
    }
    
    private var currentBalanceField: some View {
        HStack {
            Text("Current Balance")
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .frame(width: 25, height: 25)
                    .foregroundColor(Color.theme.primaryText)
                Button(action: {
                    if isPlus {
                        isPlus = false
                    }else {
                        isPlus = true
                    }
                }, label: {
                    Image(systemName: isPlus ? ConstantUtils.plusImageName : "minus")
                        .foregroundColor(isPlus ? Color.theme.green : Color.theme.red)
                        .bold()
                })
                .font(.system(size: 14).bold())
            }
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
                                currentBalance = "\(preDecimal).\(afterDecimal)"
                            }else {
                                let afterDecimal = String(splitted[1])
                                currentBalance = "\(preDecimal).\(afterDecimal)"
                            }
                        }else if splitted.count == 1 {
                            let preDecimal = String(splitted[0])
                            currentBalance = "\(preDecimal)."
                        }else {
                            currentBalance = "0."
                        }
                    } else if filtered.isEmpty && !currentBalance.isEmpty {
                        currentBalance = ""
                    } else if !filtered.isEmpty {
                        currentBalance = filtered
                    }
                })
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var monthlyEMIField: some View {
        HStack {
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
