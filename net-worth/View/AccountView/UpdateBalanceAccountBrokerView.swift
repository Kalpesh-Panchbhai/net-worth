//
//  UpdateBalanceAccountBrokerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 02/12/23.
//

import SwiftUI

struct UpdateBalanceAccountBrokerView: View {
    
    var brokerID: String
    var accountBroker: AccountInBroker
    
    var accountTransactionController = AccountTransactionController()
    
    @State var unit: String = "0.0"
    @State var isPlus = true
    @State var scenePhaseBlur = 0
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction detail") {
                    currenUnitField
                        .foregroundColor(Color.theme.primaryText)
                }
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        var accountTransaction = AccountTransaction(isAccountTransaction: false)
                        accountTransaction.accountId = accountBroker.id
                        accountTransaction.amount = (Double(unit) ?? 0.0) * (isPlus ? 1.0 : -1.0)
                        accountTransaction.operation = "UPDATE"
                        Task.init {
                            await accountTransactionController.addTransaction(accountTransaction: accountTransaction)
                            await accountViewModel.getAccountInBrokerList(brokerID: brokerID)
                            accountViewModel.hideZeroUnitAccounts()
                        }
                        dismiss()
                    }, label: {
                        Text("Update")
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        var accountTransaction = AccountTransaction(isAccountTransaction: false)
                        accountTransaction.accountId = accountBroker.id
                        accountTransaction.amount = (Double(unit) ?? 0.0) * (isPlus ? 1.0 : -1.0)
                        accountTransaction.operation = "ADD"
                        Task.init {
                            await accountTransactionController.addTransaction(accountTransaction: accountTransaction)
                            await accountViewModel.getAccountInBrokerList(brokerID: brokerID)
                            accountViewModel.hideZeroUnitAccounts()
                        }
                        dismiss()
                    }, label: {
                        Text("Add")
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                }
            }
            .navigationTitle(accountBroker.name)
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
    
    private var currenUnitField: some View {
        HStack {
            Text("Unit")
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
            TextField("Unit", text: $unit)
                .keyboardType(.decimalPad)
                .onChange(of: unit) {
                    let filtered = unit.filter {"0123456789.".contains($0)}
                    
                    if filtered.contains(".") {
                        let splitted = filtered.split(separator: ".")
                        if splitted.count >= 2 {
                            let preDecimal = String(splitted[0])
                            if String(splitted[1]).count == 5 {
                                let afterDecimal = String(splitted[1]).prefix(splitted[1].count - 1)
                                unit = "\(preDecimal).\(afterDecimal)"
                            }else {
                                let afterDecimal = String(splitted[1])
                                unit = "\(preDecimal).\(afterDecimal)"
                            }
                        }else if splitted.count == 1 {
                            let preDecimal = String(splitted[0])
                            unit = "\(preDecimal)."
                        }else {
                            unit = "0."
                        }
                    } else if filtered.isEmpty && !unit.isEmpty {
                        unit = ""
                    } else if !filtered.isEmpty {
                        unit = filtered
                    }
                }
                .multilineTextAlignment(.trailing)
        }
    }
}
