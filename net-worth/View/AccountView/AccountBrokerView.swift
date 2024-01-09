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
    @State var deletedAccount = AccountInBroker()
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    Spacer()
                    ForEach(0..<accountViewModel.accountsInBroker.count, id: \.self) { i in
                        NavigationLink(destination: {
                            AccountBrokerDetailView(brokerID: brokerID, accountID: accountViewModel.accountsInBroker[i].id!, accountViewModel: accountViewModel)
                        }, label: {
                            AccountBrokerRowView(brokerID: brokerID, accountID: accountViewModel.accountsInBroker[i].id!)
                                .frame(width: 360, height: 40)
                                .padding(8)
                                .background(Color.theme.foreground)
                                .cornerRadius(10)
                        })
                        .contextMenu {
                            Label(accountViewModel.accountsInBroker[i].id!, systemImage: ConstantUtils.infoIconImageName)
                            
                            Button(role: .destructive, action: {
                                isPresentingAccountDeleteConfirm.toggle()
                                deletedAccount = accountViewModel.accountsInBroker[i]
                            }, label: {
                                Label("Delete", systemImage: ConstantUtils.deleteImageName)
                            })
                        }
                        .confirmationDialog("Are you sure?",
                                            isPresented: $isPresentingAccountDeleteConfirm) {
                            Button("Delete account " + deletedAccount.name + "?", role: .destructive) {
                                Task.init {
                                    deletedAccount.deleted = true
                                    deletedAccount.lastUpdated = Date.now
                                    await accountInBrokerController.updateAccountInBroker(brokerID: brokerID, accountBroker: deletedAccount)
                                    await ApplicationData.loadData()
                                    await accountViewModel.getAccountInBrokerList(brokerID: brokerID)
                                    await accountViewModel.getCurrentBalanceOfAllAccountsInABroker(accountBrokerList: accountViewModel.accountsInBroker)
                                }
                            }
                        }
                    }
                }
            }
            .padding(8)
            .background(Color.theme.background)
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountInBrokerList(brokerID: brokerID)
                await accountViewModel.getCurrentBalanceOfAllAccountsInABroker(accountBrokerList: accountViewModel.accountsInBroker)
            }
        }
    }
}
