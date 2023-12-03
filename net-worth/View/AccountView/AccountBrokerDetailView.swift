//
//  AccountBrokerDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerDetailView: View {
    
    var brokerID: String
    
    var accountBroker: AccountBroker
    
    @State var tabItem = 1
    @State var isNewTransactionViewOpen = false
    
    @StateObject var accountViewModel = AccountViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            AccountBrokerDetailCardView(accountViewModel: accountViewModel)
                .cornerRadius(10)
            Picker(selection: $tabItem, content: {
                Text("Transactions (\(accountViewModel.accountTransactionList.count))").tag(1)
                Text("Chart").tag(2)
            }, label: {
                Text("Broker Account Tab View")
            })
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: tabItem, perform: { _ in
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            })
            if(tabItem == 1) {
                TransactionsView(accountViewModel: accountViewModel)
            } else {
                AccountChartView(account: Account())
            }
        }
        .navigationTitle(accountBroker.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
        .toolbar {
            ToolbarItem(content: {
                Menu(content: {
                    Button(action: {
                        self.isNewTransactionViewOpen.toggle()
                    }, label: {
                        Label("New Transaction", systemImage: "square.and.pencil")
                    })
                }, label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                })
                .font(.system(size: 14).bold())
            })
        }
        .onAppear {
            Task.init {
                await accountViewModel.getBrokerAccountCurrentBalance(accountBroker: accountBroker)
                await accountViewModel.getAccountTransactionsInBrokerAccountList(brokerID: brokerID, accountID: accountBroker.id!)
            }
        }
        .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
            Task.init {
                await accountViewModel.getBrokerAccountCurrentBalance(accountBroker: accountBroker)
                await accountViewModel.getAccountTransactionsInBrokerAccountList(brokerID: brokerID, accountID: accountBroker.id!)
            }
        }, content: {
            UpdateBalanceAccountBrokerView(brokerID: brokerID, accountBroker: accountBroker)
                .presentationDetents([.medium])
        })
    }
}
