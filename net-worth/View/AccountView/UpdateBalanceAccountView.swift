//
//  AddNewBalanceAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import SwiftUI

struct UpdateBalanceAccountView: View {
    
    private var accountController = AccountController()
    
    @State private var amount: Double = 0.0
    
    @State var isPlus = true;
    
    @State private var showingAlert = false
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    init(accountViewModel: AccountViewModel){
        self.accountViewModel = accountViewModel
    }
    
    var body: some View {
        NavigationView {
            Form {
                if(accountViewModel.account.accountType == "Saving" || accountViewModel.account.accountType == "Credit Card" || accountViewModel.account.accountType == "Loan" || accountViewModel.account.accountType == "Other") {
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
                        var updatedAccount = accountViewModel.account
                        amount = isPlus ? amount : amount * -1
                        if(accountViewModel.account.accountType == "Saving" || accountViewModel.account.accountType == "Credit Card" || accountViewModel.account.accountType == "Loan" || accountViewModel.account.accountType == "Other") {
                            updatedAccount.currentBalance = amount
                        } else {
                            updatedAccount.totalShares = amount
                        }

                        accountController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount)
                        accountController.updateAccount(account: updatedAccount)
                        Task.init {
                            await accountViewModel.getAccount(id: accountViewModel.account.id!)
                            await accountViewModel.getAccountTransactionList(id: accountViewModel.account.id!)
                        }
                    }, label: {
                        Text("Update")
                    })
                    .alert("Account Balance has been updated!", isPresented: $showingAlert, actions: {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    }, message: {
                        Text("Account Name : " + self.accountViewModel.account.accountName)
                    })
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingAlert.toggle()
                        var updatedAccount = accountViewModel.account
                        amount = isPlus ? amount : amount * -1
                        if(accountViewModel.account.accountType == "Saving" || accountViewModel.account.accountType == "Credit Card" || accountViewModel.account.accountType == "Loan" || accountViewModel.account.accountType == "Other") {
                            updatedAccount.currentBalance = updatedAccount.currentBalance + amount
                        } else {
                            updatedAccount.totalShares = updatedAccount.totalShares + amount
                        }

                        accountController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount)
                        accountController.updateAccount(account: updatedAccount)
                        Task.init {
                            await accountViewModel.getAccount(id: accountViewModel.account.id!)
                            await accountViewModel.getAccountTransactionList(id: accountViewModel.account.id!)
                        }
                    }, label: {
                        Text("Add")
                    })
                    .alert("Transaction has been added!", isPresented: $showingAlert, actions: {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    }, message: {
                        Text("Account Name : " + self.accountViewModel.account.accountName)
                    })
                }
            }
            .navigationTitle(accountViewModel.account.accountName)
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
