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
    
    var accountInBrokerController = AccountInBrokerController()
    
    @State var unit: String = "0.0"
    @State var date = Date()
    @State var isPlus = true
    @State var scenePhaseBlur = 0
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction detail") {
                    currenUnitField
                        .foregroundColor(Color.theme.primaryText)
                    DatePicker("Transaction date", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .foregroundColor(Color.theme.primaryText)
                }
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        Task.init {
                            var updatedAccount = accountBroker
                            let newAmount = isPlus ? unit.toDouble() : unit.toDouble()! * -1
                            updatedAccount.currentUnit = newAmount!
                            updatedAccount.lastUpdated = Date.now
                            await accountInBrokerController.addBrokerAccountTransaction(brokerID: brokerID, accountBroker: updatedAccount, timeStamp: date)
                            await ApplicationData.loadData()
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
                        Task.init {
                            var updatedAccount = accountBroker
                            let newAmount = isPlus ? unit.toDouble() : unit.toDouble()! * -1
                            updatedAccount.currentUnit = updatedAccount.currentUnit + newAmount!
                            updatedAccount.lastUpdated = Date.now
                            await accountInBrokerController.addBrokerAccountTransaction(brokerID: brokerID,accountBroker: updatedAccount, timeStamp: date)
                            await ApplicationData.loadData()
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
                .onChange(of: unit, perform: { _ in
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
                })
                .multilineTextAlignment(.trailing)
        }
    }
}
