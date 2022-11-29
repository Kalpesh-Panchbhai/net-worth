//
//  AddNewBalanceAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import SwiftUI

struct AddTransactionAccountView: View {
    
    private var account: Account
    
    private var accountController = AccountController()
    
    @State private var currentBalance: Double = 0.0
    
    @State var isPlus = true;
    
    @State private var showingAlert = false
    
    @Environment(\.dismiss) var dismiss
    
    init(account: Account){
        self.account = account
    }
    
    var body: some View {
        NavigationView {
            Form {
                if(account.accounttype == "Saving") {
                    currentBalanceField()
                } else if(account.accounttype == "Credit Card") {
                    currentBalanceField()
                } else if(account.accounttype == "Loan") {
                    currentBalanceField()
                } else if(account.accounttype == "Mutual Fund") {
                    currentUnitField()
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        showingAlert.toggle()
                        let accountModel = AccountModel()
                        accountModel.sysId = account.sysid!
                        accountModel.currentBalance = currentBalance
                        
                        accountController.addTransaction(accountModel: accountModel)
                        
                        if(account.accounttype == "Stock" || account.accounttype == "Mutual Fund") {
                            account.totalshare = accountModel.currentBalance
                        } else {
                            account.currentbalance = accountModel.currentBalance
                        }
                        accountController.updateAccount()
                    }, label: {
                        Label("Add Account", systemImage: "checkmark")
                    })
//                    .disabled(!allFieldsFilled())
                    .alert("Transaction has been added!", isPresented: $showingAlert, actions: {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    }, message: {
                        Text("Account Name : " + self.account.accountname!)
                    })
                }
            }
            .navigationTitle("Update Balance")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func allFieldsFilled () -> Bool {
        if account.accounttype == "Saving" {
            if currentBalance.isZero {
                return false
            } else {
                return true
            }
        }else {
            return false
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
    
    private func currentUnitField() -> HStack<TupleView<(Text, Spacer, some View)>> {
        return HStack {
            Text("Current Units")
            Spacer()
            TextField("Current Units", value: $currentBalance, formatter: Double().formatter())
                .keyboardType(.decimalPad)
        }
    }
}

struct AddNewBalanceAccountView_Previews: PreviewProvider {
    static var previews: some View {
        AddTransactionAccountView(account: Account())
    }
}