//
//  NewAccountInBrokerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 30/11/23.
//

import SwiftUI

struct NewAccountInBrokerView: View {
    
    var brokerAccountID: Int
    var accountInBrokerController = AccountInBrokerController()
    
    @State var scenePhaseBlur = 0
    
    @State var symbolSelected = SymbolDetailModel()
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account detail") {
                    SymbolPicker(symbolSelected: $symbolSelected)
                }
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        Task.init {
                            let accountBroker = AccountInBroker(accountId: brokerAccountID, symbol: symbolSelected.symbol!, name: symbolSelected.longname!)
                            await accountInBrokerController.addAccountInBroker(accountInBroker: accountBroker)
                            await accountViewModel.getAccountInBrokerList(brokerID: brokerAccountID)
                            dismiss()
                        }
                    }, label: {
                        if(!allFieldsFilled()) {
                            Image(systemName: ConstantUtils.checkmarkImageName)
                                .foregroundColor(Color.theme.primaryText.opacity(0.3))
                                .bold()
                        } else {
                            Image(systemName: ConstantUtils.checkmarkImageName)
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
        .onChange(of: scenePhase) { value in
            if(value == .active) {
                scenePhaseBlur = 0
            } else {
                scenePhaseBlur = 5
            }
        }
    }
    
    private func allFieldsFilled() -> Bool {
        return !(symbolSelected.symbol ?? "").isEmpty
    }
}
