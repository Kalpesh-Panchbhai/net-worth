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
                        var updatedAccount = accountViewModel.account
                        amount = isPlus ? amount : amount * -1
                        if(accountViewModel.account.accountType == "Saving" || accountViewModel.account.accountType == "Credit Card" || accountViewModel.account.accountType == "Loan" || accountViewModel.account.accountType == "Other") {
                            updatedAccount.currentBalance = amount
                        } else {
                            updatedAccount.totalShares = amount
                        }

                        accountController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount)
                        accountController.updateAccount(account: updatedAccount)
                        dismiss()
                    }, label: {
                        Text("Update")
                    })
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        var updatedAccount = accountViewModel.account
                        amount = isPlus ? amount : amount * -1
                        if(accountViewModel.account.accountType == "Saving" || accountViewModel.account.accountType == "Credit Card" || accountViewModel.account.accountType == "Loan" || accountViewModel.account.accountType == "Other") {
                            updatedAccount.currentBalance = updatedAccount.currentBalance + amount
                        } else {
                            updatedAccount.totalShares = updatedAccount.totalShares + amount
                        }

                        accountController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount)
                        accountController.updateAccount(account: updatedAccount)
                        dismiss()
                    }, label: {
                        Text("Add")
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
