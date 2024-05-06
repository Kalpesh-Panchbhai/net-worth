//
//  AccountBrokerDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerDetailView: View {
    
    var accountID: String
    
    var accountBrokerController = AccountInBrokerController()
    @State var account: Account
    
    @State var tabItem = 1
    @State var isNewTransactionViewOpen = false
    @State var isPresentingAccountDeleteConfirm = false
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(accountID: String, accountViewModel: AccountViewModel) {
        self.accountID = accountID
        self.accountViewModel = accountViewModel
        let accountBroker = accountViewModel.accountsInBroker.filter {
            return $0.id.elementsEqual(accountID)
        }.first ?? AccountInBroker()
        
        account = Account(accountName: accountBroker.name, currency: SettingsController().getDefaultCurrency().code, balance: BalanceAccount(currentDayValue: accountBroker.balance.currentDayValue, previousDayValue: accountBroker.balance.previousDayValue))
    }
    
    var body: some View {
        VStack {
            AccountDetailCardView(account: account)
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
                TransactionsView(account: account, accountTransactionList: accountViewModel.accountTransactionList)
            } else {
                AccountBrokerChartView(brokerID: "", accountID: accountID, symbol: accountViewModel.accountBroker.symbol, accountViewModel: accountViewModel)
            }
        }
        .confirmationDialog("Are you sure?",
                            isPresented: $isPresentingAccountDeleteConfirm) {
            Button("Delete account " + account.accountName + "?", role: .destructive) {
                Task.init {
                    await accountBrokerController.deleteAccountInBroker(accountId: accountID)
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
                            .navigationTitle(account.accountName)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarBackButtonHidden(true)
                            .navigationBarItems(
                                leading: Button(action: {
                                    self.presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: ConstantUtils.backbuttonImageName)
                                        .foregroundColor(Color.theme.primaryText)
                                        .bold()
                                }
                                    .font(.system(size: 14).bold())
                            )
                            .toolbar {
                                ToolbarItem(content: {
                                    Menu(content: {
                                        Button(role: .destructive, action: {
                                            isPresentingAccountDeleteConfirm.toggle()
                                        }, label: {
                                            Label("Delete", systemImage: ConstantUtils.deleteImageName)
                                        })
                                        
                                        Button(action: {
                                            self.isNewTransactionViewOpen.toggle()
                                        }, label: {
                                            Label("New Transaction", systemImage: ConstantUtils.newTransactionImageName)
                                        })
                                    }, label: {
                                        Image(systemName: ConstantUtils.menuImageName)
                                            .foregroundColor(Color.theme.primaryText)
                                            .bold()
                                    })
                                    .font(.system(size: 14).bold())
                                })
                            }
                            .onAppear {
                                Task.init {
                                    await accountViewModel.getAccountTransactionList(id: accountID)
                                }
                            }
                            .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
                                
                            }, content: {
                                UpdateBalanceAccountBrokerView(brokerID: accountID, accountBroker: accountViewModel.accountBroker, accountViewModel: accountViewModel)
                                    .presentationDetents([.medium])
                            })
    }
}
