//
//  AddNewBalanceAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import SwiftUI

struct UpdateBalanceAccountView: View {
    
    var accountController = AccountController()
    var accountTransactionController = AccountTransactionController()
    
    @State var amount: Double = 0.0
    @State var date = Date()
    @State var isPlus = true
    @State var scenePhaseBlur = 0
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction detail") {
                    currentBalanceField
                        .foregroundColor(Color.theme.text)
                    DatePicker("Transaction date", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .foregroundColor(Color.theme.text)
                }
                .listRowBackground(Color.theme.background)
                .foregroundColor(Color.theme.text)
            }
            .shadow(color: Color.theme.text.opacity(0.3),radius: 10, x: 0, y: 5)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        var updatedAccount = accountViewModel.account
                        amount = isPlus ? amount : amount * -1
                        updatedAccount.currentBalance = amount
                        Task.init {
                            await accountTransactionController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount, timestamp: date, operation: "Update")
                        }
                        dismiss()
                    }, label: {
                        Text("Update")
                            .foregroundColor(Color.theme.text)
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
                            await accountTransactionController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount, timestamp: date, operation: "Add")
                        }
                        dismiss()
                    }, label: {
                        Text("Add")
                            .foregroundColor(Color.theme.text)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                }
            }
            .navigationTitle(accountViewModel.account.accountName)
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
    }
    
    private var currentBalanceField: some View {
        HStack {
            Text("Amount")
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .frame(width: 25, height: 25)
                    .foregroundColor(Color.theme.text)
                    .shadow(color: Color.theme.text.opacity(0.3),radius: 3, x: 0, y: 5)
                Button(action: {
                    if isPlus {
                        isPlus = false
                    }else {
                        isPlus = true
                    }
                }, label: {
                    Image(systemName: isPlus ? "plus" : "minus")
                        .foregroundColor(isPlus ? Color.theme.green : Color.theme.red)
                        .bold()
                })
                .font(.system(size: 14).bold())
            }
            Spacer()
            TextField("Amount", value: $amount, formatter: Double().formatter())
                .keyboardType(.decimalPad)
        }
    }
}
