//
//  AddNewBalanceAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/11/22.
//

import SwiftUI

struct UpdateBalanceAccountView: View {
    
    var accountId: Int
    var accountTransactionController = AccountTransactionController()
    
    @State var amount: String = "0.0"
    @State var isPlus = true
    @State var scenePhaseBlur = 0
    @State var date = Date()
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction detail") {
                    currentBalanceField
                        .foregroundColor(Color.theme.primaryText)
                    transactionDate
                        .foregroundColor(Color.theme.primaryText)
                }
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        var accountTransaction = AccountTransactionRestModel()
                        accountTransaction.accountId = accountId
                        accountTransaction.transactionDate = date.localToLocalString()
                        accountTransaction.value = (Double(amount) ?? 0.0) * (isPlus ? 1.0 : -1.0)
                        accountTransaction.operation = "add"
                        Task.init {
                            await accountTransactionController.addAccountTransaction(accountTransaction: accountTransaction)
                            await accountViewModel.getAccountList()
                        }
                        dismiss()
                    }, label: {
                        Text("Add")
                    })
                    .font(.system(size: 14).bold())
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        var accountTransaction = AccountTransactionRestModel()
                        accountTransaction.accountId = accountId
                        accountTransaction.transactionDate = date.localToLocalString()
                        accountTransaction.value = (Double(amount) ?? 0.0) * (isPlus ? 1.0 : -1.0)
                        accountTransaction.operation = "update"
                        Task.init {
                            await accountTransactionController.addAccountTransaction(accountTransaction: accountTransaction)
                            await accountViewModel.getAccountList()
                        }
                        dismiss()
                    }, label: {
                        Text("Update")
                    })
                    .font(.system(size: 14).bold())
                }
            }
            .navigationTitle(accountViewModel.account.name)
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
    
    private var currentBalanceField: some View {
        HStack {
            Text("Amount")
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .frame(width: 25, height: 25)
                    .foregroundColor(Color.theme.primaryText)
                Button(action: {
                    if isPlus {
                        isPlus = false
                    }else {
                        isPlus = true
                    }
                }, label: {
                    Image(systemName: isPlus ? ConstantUtils.plusImageName : "minus")
                        .foregroundColor(isPlus ? Color.theme.green : Color.theme.red)
                        .bold()
                })
                .font(.system(size: 14).bold())
            }
            Spacer()
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
                .onChange(of: amount) {
                    let filtered = amount.filter {"0123456789.".contains($0)}
                    
                    if filtered.contains(".") {
                        let splitted = filtered.split(separator: ".")
                        if splitted.count >= 2 {
                            let preDecimal = String(splitted[0])
                            if String(splitted[1]).count == 3 {
                                let afterDecimal = String(splitted[1]).prefix(splitted[1].count - 1)
                                amount = "\(preDecimal).\(afterDecimal)"
                            }else {
                                let afterDecimal = String(splitted[1])
                                amount = "\(preDecimal).\(afterDecimal)"
                            }
                        }else if splitted.count == 1 {
                            let preDecimal = String(splitted[0])
                            amount = "\(preDecimal)."
                        }else {
                            amount = "0."
                        }
                    } else if filtered.isEmpty && !amount.isEmpty {
                        amount = ""
                    } else if !filtered.isEmpty {
                        amount = filtered
                    }
                }
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var transactionDate: some View {
        HStack{
            DatePicker("Transaction Date", selection: $date, in: ...Date(), displayedComponents: [.date])
        }
    }
}
