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
                        .foregroundColor(Color.navyBlue)
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
                            await accountTransactionController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount, timestamp: date, operation: "Update")
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
                            await accountTransactionController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount, timestamp: date, operation: "Add")
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
    
    private var currentBalanceField: some View {
        HStack {
            Text("Amount")
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .frame(width: 25, height: 25)
                    .foregroundColor(Color.white)
                    .shadow(color: Color.navyBlue, radius: 3)
                Button(action: {
                    if isPlus {
                        isPlus = false
                    }else {
                        isPlus = true
                    }
                }, label: {
                    Image(systemName: isPlus ? "plus" : "minus")
                        .foregroundColor(isPlus ? Color.green : Color.red)
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
