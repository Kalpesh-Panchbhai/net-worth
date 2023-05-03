//
//  AccountDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailView: View {
    
    private var dates = Array(1...28)
    private var account: Account
    private var accountController = AccountController()
    
    @State private var show = false
    @State var isNewTransactionViewOpen = false
    @State var paymentDate = 0
    @State var tabItem = 1
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(account: Account, accountViewModel: AccountViewModel) {
        self.account = account
        self.accountViewModel = accountViewModel
    }
    
    var body: some View {
        VStack {
            VStack {
                AccountDetailCardView(accountViewModel: accountViewModel)
                    .cornerRadius(10)
                    .shadow(color: Color.gray, radius: 3)
                Picker(selection: $tabItem, content: {
                    Text("Transactions").tag(1)
                    Text("Charts").tag(2)
                }, label: {
                    Label("CCC", systemImage: "")
                })
                .pickerStyle(SegmentedPickerStyle())
                if(tabItem == 1) {
                    TransactionsView(accountViewModel: accountViewModel)
                } else {
                    AccountChartView(account: account)
                }
            }
        }
        .toolbar {
            ToolbarItem(content: {
                Menu(content: {
                    Button(role: .destructive, action: {
                        Task.init {
                            try await accountController.deleteAccount(account: account)
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Label("Delete", systemImage: "trash")
                    })
                    
                    Button(action: {
                        self.isNewTransactionViewOpen.toggle()
                    }, label: {
                        Label("New Transaction", systemImage: "square.and.pencil")
                    })
                    
                    if(accountViewModel.account.accountType != "Saving") {
                        if(!accountViewModel.account.paymentReminder) {
                            Picker(selection: $paymentDate, content: {
                                ForEach(dates, id: \.self) {
                                    Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                                }
                            }, label: {
                                Label("Enable Notification", systemImage: "speaker.wave.1.fill")
                            })
                            .onChange(of: paymentDate) { _ in
                                accountViewModel.account.paymentReminder = true
                                accountViewModel.account.paymentDate = paymentDate
                                accountController.updateAccount(account: accountViewModel.account)
                                NotificationController().enableNotification(account: accountViewModel.account)
                            }
                            .pickerStyle(MenuPickerStyle())
                        } else {
                            Button(action: {
                                accountViewModel.account.paymentReminder = false
                                accountViewModel.account.paymentDate = 0
                                accountController.updateAccount(account: accountViewModel.account)
                                NotificationController().removeNotification(id: accountViewModel.account.id!)
                                paymentDate = 0
                            }, label: {
                                Label("Disable Notification", systemImage: "speaker.slash.fill")
                            })
                            
                            Picker(selection: $paymentDate, content: {
                                ForEach(dates, id: \.self) {
                                    Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                                }
                            }, label: {
                                Label("Change Date", systemImage: "calendar.circle.fill")
                            })
                            .onChange(of: paymentDate) { _ in
                                accountViewModel.account.paymentReminder = true
                                accountViewModel.account.paymentDate = paymentDate
                                accountController.updateAccount(account: accountViewModel.account)
                                NotificationController().enableNotification(account: accountViewModel.account)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    
                }, label: {
                    Image(systemName: "ellipsis")
                })
            })
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccount(id: account.id!)
                paymentDate = accountViewModel.account.paymentDate
                await accountViewModel.getAccountTransactionList(id: account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
            }
        }
        .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
            Task.init {
                await accountViewModel.getAccount(id: accountViewModel.account.id!)
                await accountViewModel.getAccountTransactionList(id: accountViewModel.account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: accountViewModel.account.id!)
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
            }
        }, content: {
            UpdateBalanceAccountView(accountViewModel: accountViewModel)
        })
        .background(.black)
    }
}
