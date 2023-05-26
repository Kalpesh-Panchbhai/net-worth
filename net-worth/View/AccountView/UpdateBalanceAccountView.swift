//
//  AddNewBalanceAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import SwiftUI

struct UpdateBalanceAccountView: View {
    
    @Environment(\.scenePhase) var scenePhase
    @State var scenePhaseBlur = 0
    
    var accountController = AccountController()
    
    @State var amount: Double = 0.0
    @State var date = Date()
    
    @State var isPlus = true;
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction detail") {
                    currentBalanceField()
                        .colorMultiply(Color.navyBlue)
                    DatePicker("Transaction date", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .colorMultiply(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        var updatedAccount = accountViewModel.account
                        amount = isPlus ? amount : amount * -1
                        updatedAccount.currentBalance = amount
                        Task.init {
                                try await accountController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount, timestamp: date, operation: "Update")
                        }
                        dismiss()
                    }, label: {
                        Text("Update")
                            .foregroundColor(Color.lightBlue)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        var updatedAccount = accountViewModel.account
                        amount = isPlus ? amount : amount * -1
                        updatedAccount.currentBalance = amount
                        Task.init {
                                try await accountController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount, timestamp: date, operation: "Add")
                        }
                        dismiss()
                    }, label: {
                        Text("Add")
                            .foregroundColor(Color.lightBlue)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                }
            }
            .navigationTitle(accountViewModel.account.accountName)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.navyBlue)
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
}
