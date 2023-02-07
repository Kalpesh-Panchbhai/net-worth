//
//  AddNewBalanceAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import SwiftUI

struct UpdateBalanceAccountView: View {
    
    var account : Binding<Account>
    
    private var accountController = AccountController()
    
    @State private var amount: Double = 0.0
    
    @State var isPlus = true;
    
    @State private var showingAlert = false
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    init(account: Binding<Account>, accountViewModel: AccountViewModel){
        self.account = account
        self.accountViewModel = accountViewModel
    }
    
    var body: some View {
        NavigationView {
            Form {
                if(account.wrappedValue.accountType == "Saving" || account.wrappedValue.accountType == "Credit Card" || account.wrappedValue.accountType == "Loan" || account.wrappedValue.accountType == "Other") {
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
                        let updatedAccount = account
                        amount = isPlus ? amount : amount * -1
                        if(account.wrappedValue.accountType == "Saving" || account.wrappedValue.accountType == "Credit Card" || account.wrappedValue.accountType == "Loan" || account.wrappedValue.accountType == "Other") {
                            updatedAccount.wrappedValue.currentBalance = amount
                        } else {
                            updatedAccount.wrappedValue.totalShares = amount
                        }

                        accountController.addTransaction(accountID: account.wrappedValue.id!, account: updatedAccount.wrappedValue)
                        accountController.updateAccount(account: updatedAccount.wrappedValue)
                        Task.init {
                            await accountViewModel.getAccountList()
                            await accountViewModel.getAccount(id: account.wrappedValue.id!)
                            await accountViewModel.getTotalBalance()
                        }
                    }, label: {
                        Text("Update")
                    })
                    .alert("Account Balance has been updated!", isPresented: $showingAlert, actions: {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    }, message: {
                        Text("Account Name : " + self.account.wrappedValue.accountName)
                    })
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingAlert.toggle()
                        let updatedAccount = account
                        amount = isPlus ? amount : amount * -1
                        if(account.wrappedValue.accountType == "Saving" || account.wrappedValue.accountType == "Credit Card" || account.wrappedValue.accountType == "Loan" || account.wrappedValue.accountType == "Other") {
                            updatedAccount.wrappedValue.currentBalance = account.wrappedValue.currentBalance + amount
                        } else {
                            updatedAccount.wrappedValue.totalShares = account.wrappedValue.totalShares + amount
                        }

                        accountController.addTransaction(accountID: account.wrappedValue.id!, account: updatedAccount.wrappedValue)
                        accountController.updateAccount(account: updatedAccount.wrappedValue)
                        Task.init {
                            await accountViewModel.getAccountList()
                            await accountViewModel.getAccount(id: account.wrappedValue.id!)
                            await accountViewModel.getTotalBalance()
                        }
                    }, label: {
                        Text("Add")
                    })
                    .alert("Transaction has been added!", isPresented: $showingAlert, actions: {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    }, message: {
                        Text("Account Name : " + self.account.wrappedValue.accountName)
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
