//
//  AddNewBalanceAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import SwiftUI

struct UpdateBalanceAccountView: View {
    
    private var account: Account
    
    private var accountController = AccountController()
    
    @State private var amount: Double = 0.0
    
    @State var isPlus = true;
    
    @State private var showingAlert = false
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    init(account: Account, accountViewModel: AccountViewModel){
        self.account = account
        self.accountViewModel = accountViewModel
    }
    
    var body: some View {
        NavigationView {
            Form {
                if(account.accountType == "Saving" || account.accountType == "Credit Card" || account.accountType == "Loan" || account.accountType == "Other") {
                    currentBalanceField()
                }
                else {
                    currentUnitField()
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        showingAlert.toggle()
                        var updatedAccount = account
                        amount = isPlus ? amount : amount * -1
                        if(account.accountType == "Saving" || account.accountType == "Credit Card" || account.accountType == "Loan" || account.accountType == "Other") {
                            updatedAccount.currentBalance = amount
                        } else {
                            updatedAccount.totalShares = amount
                        }

                        accountController.addTransaction(accountID: account.id!, account: updatedAccount)
                        accountController.updateAccount(account: updatedAccount)
                        accountViewModel.getAccountList()
                    }, label: {
                        Text("Update")
                    })
                    .alert("Account Balance has been updated!", isPresented: $showingAlert, actions: {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    }, message: {
                        Text("Account Name : " + self.account.accountName)
                    })
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingAlert.toggle()
                        var updatedAccount = account
                        amount = isPlus ? amount : amount * -1
                        if(account.accountType == "Saving" || account.accountType == "Credit Card" || account.accountType == "Loan" || account.accountType == "Other") {
                            updatedAccount.currentBalance = account.currentBalance + amount
                        } else {
                            updatedAccount.totalShares = account.totalShares + amount
                        }

                        accountController.addTransaction(accountID: account.id!, account: updatedAccount)
                        accountController.updateAccount(account: updatedAccount)
                        accountViewModel.getAccountList()
                    }, label: {
                        Text("Add")
                    })
                    .alert("Transaction has been added!", isPresented: $showingAlert, actions: {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    }, message: {
                        Text("Account Name : " + self.account.accountName)
                    })
                }
            }
            .navigationTitle(account.accountName)
        }
    }
    
    private func currentBalanceField() -> HStack<TupleView<(Text, Spacer, Button<Label<Text, Image>>, Spacer, some View)>> {
        return HStack {
            Text("Amount")
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
            TextField("Amount", value: $amount, formatter: Double().formatter())
                .keyboardType(.decimalPad)
        }
    }
    
    private func currentUnitField() -> HStack<TupleView<(Text, Spacer, Button<Label<Text, Image>>, Spacer, some View)>> {
        return HStack {
            Text("Units")
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
            TextField("Units", value: $amount, formatter: Double().formatter())
                .keyboardType(.decimalPad)
        }
    }
}
