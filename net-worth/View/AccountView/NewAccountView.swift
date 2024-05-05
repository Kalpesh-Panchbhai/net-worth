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
    @State var symbolType: String = ConstantUtils.noneAccountType
    @State var accountName: String = ""
    @State var currencySelected: Currency = Currency()
    @State var filterCurrencyList = CurrencyList().currencyList
    @State var currencyChanged = false
    @State var monthlyEmi: Double = 0.0
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
                        currencySelected = SettingsController().getDefaultCurrency()
                        selectedWatchList = Watch()
                        isPlus = true
                        loanPaymentDate = 1
                        monthlyEmi = 0.0
                        accountOpenedDate = Date()
                    }
                    if(accountType == ConstantUtils.savingAccountType) {
                        nameField(labelName: "Account Name")
                            .foregroundColor(Color.theme.primaryText)
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
                        watchListPicker
                        accountOpenedDatePicker
                    }
                    else if(accountType == ConstantUtils.creditCardAccountType) {
                        nameField(labelName: "Credit Card Name")
                            .foregroundColor(Color.theme.primaryText)
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
                        watchListPicker
                        accountOpenedDatePicker
                    }
                    else if(accountType == ConstantUtils.loanAccountType) {
                        Picker(selection: $loanType, label: Text("Loan Type")) {
                            Text("Consumer").tag("Consumer")
                            Text("Non Consumer").tag("Non Consumer")
                        }
                        .foregroundColor(Color.theme.primaryText)
                        
                        nameField(labelName: "Loan Name")
                            .foregroundColor(Color.theme.primaryText)
                        if(loanType.elementsEqual("Consumer")) {
                            monthlyEMIField
                                .foregroundColor(Color.theme.primaryText)
                            loanPaymentDateField(labelName: "Loan payment date")
                                .foregroundColor(Color.theme.primaryText)
                        }
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
                        watchListPicker
                        accountOpenedDatePicker
                    } else if(accountType == ConstantUtils.brokerAccountType) {
                        nameField(labelName: "Broker Name")
                            .foregroundColor(Color.theme.primaryText)
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
                        watchListPicker
                    } else if(accountType == ConstantUtils.otherAccountType) {
                        nameField(labelName: "Account Name")
                            .foregroundColor(Color.theme.primaryText)
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
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
                        if(accountType.elementsEqual(ConstantUtils.loanAccountType)) {
                            newAccount.loanType = loanType
                        }
                        newAccount.accountName = accountName
                        newAccount.currency = currencySelected.code
                        Task.init {
                            await accountController.addAccount(newAccount: newAccount)
//                            newAccount.id = accountID
//                            await accountViewModel.getAccountList()
//                            if(selectedWatchList.id != "") {
//                                selectedWatchList.accountID.append(accountID)
//                                selectedWatchList.accountID.sort(by: { item1, item2 in
//                                    accountViewModel.accountList.filter { account1 in
//                                        account1.id!.elementsEqual(item1)
//                                    }.first!.accountName <= accountViewModel.accountList.filter { account2 in
//                                        account2.id!.elementsEqual(item2)
//                                    }.first!.accountName
//                                })
//                                watchController.addAccountToWatchList(watch: selectedWatchList)
//                            }
//                            var watch = await watchController.getDefaultWatchList()
//                            watch.accountID.append(accountID)
//                            watch.accountID.sort(by: { item1, item2 in
//                                accountViewModel.accountList.filter { account1 in
//                                    account1.id!.elementsEqual(item1)
//                                }.first!.accountName <= accountViewModel.accountList.filter { account2 in
//                                    account2.id!.elementsEqual(item2)
//                                }.first!.accountName
//                            })
//                            watchController.addAccountToWatchList(watch: watch)
//                            await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
//                            if(accountType.elementsEqual(ConstantUtils.loanAccountType) && loanType.elementsEqual("Consumer")) {
//                                Task.init {
//                                    await accountTransactionController.addLoanAccountEMITransaction(account: newAccount, emiDate: loanPaymentDate, accountOpenedDate: accountOpenedDate, monthlyEmiAmount: monthlyEmi)
//                                }
//                            }
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
        if accountType == ConstantUtils.savingAccountType {
            if accountName.isEmpty || currencySelected.name.isEmpty {
                return false
            } else {
                return true
            }
        } else if accountType == ConstantUtils.creditCardAccountType {
            if accountName.isEmpty || currencySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        } else if accountType == ConstantUtils.loanAccountType {
            if accountName.isEmpty || currencySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        } else if accountType == ConstantUtils.brokerAccountType {
            if accountName.isEmpty || currencySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        } else if accountType == ConstantUtils.otherAccountType {
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
    
    private var monthlyEMIField: some View {
        HStack {
            Text("Monthly EMI")
            Spacer()
            TextField("Monthly EMI", value: $monthlyEmi, formatter: Double().formatter())
                .keyboardType(.decimalPad)
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
