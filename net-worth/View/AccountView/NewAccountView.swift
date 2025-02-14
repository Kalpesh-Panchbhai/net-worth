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
    @State var name: String = ""
    @State var currencySelected: Currency = Currency()
    @State var dates = Array(1...28)
    @State var isPlus = true
    
    @EnvironmentObject var accountViewModel : AccountViewModel
    @EnvironmentObject var watchViewModel : WatchViewModel
    
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
                    .onChange(of: accountType) {
                        name=""
                        currencySelected = SettingsController().getDefaultCurrency()
                        isPlus = true
                    }
                    if(accountType == ConstantUtils.savingAccountType) {
                        nameField(labelName: "Account Name")
                            .foregroundColor(Color.theme.primaryText)
                    }
                    else if(accountType == ConstantUtils.creditCardAccountType) {
                        nameField(labelName: "Credit Card Name")
                            .foregroundColor(Color.theme.primaryText)
                    }
                    else if(accountType == ConstantUtils.loanAccountType) {
                        nameField(labelName: "Loan Name")
                            .foregroundColor(Color.theme.primaryText)
                    } else if(accountType == ConstantUtils.brokerAccountType) {
                        nameField(labelName: "Broker Name")
                            .foregroundColor(Color.theme.primaryText)
                    } else if(accountType == ConstantUtils.otherAccountType) {
                        nameField(labelName: "Account Name")
                            .foregroundColor(Color.theme.primaryText)
                    }
                    if(accountType != ConstantUtils.noneAccountType) {
                        CurrencyPicker(currenySelected: $currencySelected)
                            .foregroundColor(Color.theme.primaryText)
                    }
                }
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        var newAccount = AccountRestModel()
                        newAccount.userId = ApplicationData.shared.userId
                        newAccount.active = true
                        newAccount.name = name
                        newAccount.type = accountType
                        newAccount.currency = currencySelected.code
                        Task.init {
                            await accountController.addAccount(newAccount: newAccount)
                            await accountViewModel.getAccountList()
                            await watchViewModel.getAllWatchList()
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
        .onChange(of: scenePhase) {
            if($0 == .active) {
                scenePhaseBlur = 0
            } else {
                scenePhaseBlur = 5
            }
        }
    }
    
    private func allFieldsFilled () -> Bool {
        if accountType == ConstantUtils.savingAccountType {
            if name.isEmpty || currencySelected.name.isEmpty {
                return false
            } else {
                return true
            }
        } else if accountType == ConstantUtils.creditCardAccountType {
            if name.isEmpty || currencySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        } else if accountType == ConstantUtils.loanAccountType {
            if name.isEmpty || currencySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        } else if accountType == ConstantUtils.brokerAccountType {
            if name.isEmpty || currencySelected.name.isEmpty  {
                return false
            } else {
                return true
            }
        } else if accountType == ConstantUtils.otherAccountType {
            if name.isEmpty || currencySelected.name.isEmpty  {
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
            TextField(labelName, text: $name)
        }
    }
}
