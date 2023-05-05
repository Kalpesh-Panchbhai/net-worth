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
    
    @State private var showAddWatchListView = false
    @State var isNewTransactionViewOpen = false
    @State var isPresentingAccountDeleteConfirm = false
    @State var paymentDate = 0
    @State var isActive = true
    @State var tabItem = 1
    @State var showZeroAlert = false
    
    @ObservedObject var accountViewModel: AccountViewModel
    @StateObject var watchViewModel = WatchViewModel()
    
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
                    Text("Chart").tag(2)
                    Text("WatchLists").tag(3)
                }, label: {
                    Text("Account Tab View")
                })
                .pickerStyle(SegmentedPickerStyle())
                if(tabItem == 1) {
                    TransactionsView(accountViewModel: accountViewModel)
                } else if(tabItem == 2) {
                    AccountChartView(account: account)
                } else {
                    AccountWatchListView(account: account, watchViewModel: watchViewModel)
                }
            }
            .alert(isPresented: $showZeroAlert) {
                Alert(title: Text("Current Balance should be equal to zero to make it inactive!"))
            }
            .confirmationDialog("Are you sure?",
                                isPresented: $isPresentingAccountDeleteConfirm) {
                Button("Delete account " + account.accountName + "?", role: .destructive) {
                    Task.init {
                        try await accountController.deleteAccount(account: account)
                    }
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .toolbar {
            ToolbarItem(content: {
                Button(action: {
                    self.showAddWatchListView.toggle()
                }, label: {
                    if(watchViewModel.watchListForAccount.count > 1) {
                        Image(systemName: "bookmark.fill")
                    } else {
                        Image(systemName: "bookmark")
                    }
                })
            })
            
            ToolbarItem(content: {
                Menu(content: {
                    Button(role: .destructive, action: {
                        isPresentingAccountDeleteConfirm.toggle()
                    }, label: {
                        Label("Delete", systemImage: "trash")
                    })
                    
                    Button(action: {
                        self.isActive.toggle()
                    }, label: {
                        if(isActive) {
                            Label("Make Inactive", systemImage: "xmark.shield")
                        } else {
                            Label("Make Active", systemImage: "checkmark.shield")
                        }
                    })
                    .onChange(of: isActive, perform: { isActive in
                        if(!isActive) {
                            if(!accountViewModel.account.currentBalance.isZero) {
                                self.showZeroAlert.toggle()
                                self.isActive.toggle()
                            } else {
                                accountViewModel.account.active = isActive
                                accountViewModel.account.paymentReminder = false
                                accountViewModel.account.paymentDate = 0
                                accountController.updateAccount(account: accountViewModel.account)
                                NotificationController().removeNotification(id: accountViewModel.account.id!)
                                paymentDate = 0
                            }
                        } else {
                            accountViewModel.account.active = isActive
                            accountController.updateAccount(account: accountViewModel.account)
                        }
                    })
                    
                    if(isActive) {
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
                isActive = accountViewModel.account.active
                await accountViewModel.getAccountTransactionList(id: account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                await watchViewModel.getWatchListByAccount(accountID: account.id!)
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
        .sheet(isPresented: $showAddWatchListView, onDismiss: {
            Task.init {
                await watchViewModel.getWatchListByAccount(accountID: account.id!)
            }
        }, content: {
            AddWatchListAccountView(watchViewModel: watchViewModel, account: account)
        })
        .background(.black)
    }
}
