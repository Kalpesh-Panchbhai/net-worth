//
//  NewAccountInBrokerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 30/11/23.
//

import SwiftUI

struct NewAccountInBrokerView: View {
    
    var brokerAccountID: String
    var brokerAccountController = BrokerAccountController()
    
    @State var scenePhaseBlur = 0
    
    @State var symbolSelected = SymbolDetailModel()
    @State var currentUnit: String = "0.0"
    @State var accountOpenedDate = Date()
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account detail") {
                    SymbolPicker(symbolSelected: $symbolSelected)
                    currentBalanceField
                        .foregroundColor(Color.theme.primaryText)
                    accountOpenedDatePicker
                }
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        let accountBroker = AccountInBroker(timestamp: accountOpenedDate, symbol: symbolSelected.symbol!, name: symbolSelected.longname!, currentUnit: Double(currentUnit)!)
                        brokerAccountController.addAccountInBroker(brokerID: brokerAccountID, accountBroker: accountBroker)
                        
                        dismiss()
                    }, label: {
                        if(!allFieldsFilled()) {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.theme.primaryText.opacity(0.3))
                                .bold()
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.theme.primaryText)
                                .bold()
                        }
                    })
                    .font(.system(size: 14).bold())
                    .disabled(!allFieldsFilled())
                }
            }
            .navigationTitle("New Account")
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
    
    private func allFieldsFilled () -> Bool {
        return !(symbolSelected.symbol ?? "").isEmpty
    }
    
    var accountOpenedDatePicker: some View {
        DatePicker("Opened date", selection: $accountOpenedDate, in: ...Date(), displayedComponents: [.date])
            .foregroundColor(Color.theme.primaryText)
    }
    
    private var currentBalanceField: some View {
        HStack {
            Text("Current Units")
            Spacer()
            TextField("Current Units", text: $currentUnit)
                .keyboardType(.decimalPad)
                .onChange(of: currentUnit, perform: { _ in
                    let filtered = currentUnit.filter {"0123456789.".contains($0)}
                    
                    if filtered.contains(".") {
                        let splitted = filtered.split(separator: ".")
                        if splitted.count >= 2 {
                            let preDecimal = String(splitted[0])
                            if String(splitted[1]).count == 5 {
                                let afterDecimal = String(splitted[1]).prefix(splitted[1].count - 1)
                                currentUnit = "\(preDecimal).\(afterDecimal)"
                            }else {
                                let afterDecimal = String(splitted[1])
                                currentUnit = "\(preDecimal).\(afterDecimal)"
                            }
                        } else if splitted.count == 1 {
                            let preDecimal = String(splitted[0])
                            currentUnit = "\(preDecimal)."
                        } else {
                            currentUnit = "0."
                        }
                    } else if filtered.isEmpty && !currentUnit.isEmpty {
                        currentUnit = ""
                    } else if !filtered.isEmpty {
                        currentUnit = filtered
                    }
                })
                .multilineTextAlignment(.trailing)
        }
    }
}
