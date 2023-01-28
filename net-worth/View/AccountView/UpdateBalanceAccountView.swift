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
    
    init(account: Account){
        self.account = account
    }
    
    var body: some View {
        NavigationView {
            Form {
                if(account.accounttype == "Saving" || account.accounttype == "Credit Card" || account.accounttype == "Loan" || account.accounttype == "Other") {
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
                        let accountModel = AccountModel()
                        accountModel.sysId = account.sysid!
                        accountModel.accountType = account.accounttype!
                        amount = isPlus ? amount : amount * -1
                        if(account.accounttype == "Saving" || account.accounttype == "Credit Card" || account.accounttype == "Loan" || account.accounttype == "Other") {
                            accountModel.currentBalance = amount
                        } else {
                            accountModel.totalShares = amount
                        }
                        
                        accountController.addTransaction(accountModel: accountModel)
                        
                        if(account.accounttype == "Saving" || account.accounttype == "Credit Card" || account.accounttype == "Loan" || account.accounttype == "Other") {
                            account.currentbalance = accountModel.currentBalance
                        } else {
                            account.totalshare = accountModel.totalShares
                        }
                        accountController.updateAccount()
                    }, label: {
                        Text("Update")
                    })
                    .alert("Account Balance has been updated!", isPresented: $showingAlert, actions: {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    }, message: {
                        Text("Account Name : " + self.account.accountname!)
                    })
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingAlert.toggle()
                        let accountModel = AccountModel()
                        accountModel.sysId = account.sysid!
                        accountModel.accountType = account.accounttype!
                        amount = isPlus ? amount : amount * -1
                        if(account.accounttype == "Saving" || account.accounttype == "Credit Card" || account.accounttype == "Loan" || account.accounttype == "Other") {
                            accountModel.currentBalance = account.currentbalance + amount
                        } else {
                            accountModel.totalShares = account.totalshare + amount
                        }
                        
                        accountController.addTransaction(accountModel: accountModel)
                        
                        if(account.accounttype == "Saving" || account.accounttype == "Credit Card" || account.accounttype == "Loan" || account.accounttype == "Other") {
                            account.currentbalance = accountModel.currentBalance
                        } else {
                            account.totalshare = accountModel.totalShares
                        }
                        accountController.updateAccount()
                    }, label: {
                        Text("Add")
                    })
                    .alert("Transaction has been added!", isPresented: $showingAlert, actions: {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    }, message: {
                        Text("Account Name : " + self.account.accountname!)
                    })
                }
            }
            .navigationTitle(account.accountname!)
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

struct UpdateBalanceAccountView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateBalanceAccountView(account: Account())
    }
}
