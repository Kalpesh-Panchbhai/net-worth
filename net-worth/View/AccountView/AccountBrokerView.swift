//
//  AccountBrokerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerView: View {
    
    var brokerID: String
    
    var accountInBrokerController = AccountInBrokerController()
    
    @State var isPresentingAccountDeleteConfirm = false
    @State var isNewTransactionViewOpen = false
    @State var selectedAccount = AccountInBroker()
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    Spacer()
                    ForEach(0..<accountViewModel.accountsInBroker.count, id: \.self) { i in
                        AccountBrokerRowView(account: accountViewModel.accountsInBroker[i])
                            .frame(width: 360, height: 40)
                            .padding(8)
                            .background(Color.theme.foreground)
                            .cornerRadius(10)
                            .contextMenu {
                                Button(action: {
                                    self.isNewTransactionViewOpen.toggle()
                                    self.selectedAccount = accountViewModel.accountsInBroker[i]
                                }, label: {
                                    Label("New Transaction", systemImage: ConstantUtils.newTransactionImageName)
                                })
                                
                                Button(role: .destructive, action: {
                                    self.isPresentingAccountDeleteConfirm.toggle()
                                    self.selectedAccount = accountViewModel.accountsInBroker[i]
                                }, label: {
                                    Label("Delete", systemImage: ConstantUtils.deleteImageName)
                                })
                            }
                    }
                }
                .confirmationDialog("Are you sure?",
                                    isPresented: $isPresentingAccountDeleteConfirm) {
                    Button("Delete account " + selectedAccount.name + "?", role: .destructive) {
                        Task.init {
                            await accountInBrokerController.deleteAccountInBroker(accountId: selectedAccount.id)
                            await accountViewModel.getAccountInBrokerList(brokerID: brokerID)
                            accountViewModel.hideZeroUnitAccounts()
                        }
                    }
                }
            }
            .sheet(isPresented: $isNewTransactionViewOpen, content: {
                UpdateBalanceAccountBrokerView(brokerID: brokerID, accountBroker: selectedAccount)
                    .presentationDetents([.medium])
            })
            .padding(8)
            .background(Color.theme.background)
        }
    }
}
