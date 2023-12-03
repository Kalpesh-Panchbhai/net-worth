//
//  AccountDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailView: View {
    
    var dates = Array(1...28)
    var account: Account
    var accountController = AccountController()
    
    @State var initialLoadForActiveButton = false
    @State var initialLoadForPaymentButton = false
    @State var showAddWatchListView = false
    @State var isNewTransactionViewOpen = false
    @State var isNewAccountInBrokerViewOpen = false
    @State var isPresentingAccountDeleteConfirm = false
    @State var paymentDate = 0
    @State var isActive = true
    @State var tabItem = 1
    @State var showZeroAlert = false
    @State var failedToMarkInActive = false
    
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(account: Account, accountViewModel: AccountViewModel, watchViewModel: WatchViewModel) {
        self.account = account
        self.accountViewModel = accountViewModel
        self.watchViewModel = watchViewModel
        
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.theme.primaryText)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.theme.background)], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.theme.primaryText)], for: .normal)
    }
    
    var body: some View {
        VStack {
            VStack {
                if(accountViewModel.account.accountType == "Broker") {
                    AccountBrokerDetailCardView(accountViewModel: accountViewModel)
                        .cornerRadius(10)
                } else {
                    AccountDetailCardView(accountViewModel: accountViewModel)
                        .cornerRadius(10)
                }
                Picker(selection: $tabItem, content: {
                    if(accountViewModel.account.accountType == "Broker") {
                        Text("Accounts (\(accountViewModel.accountsInBroker.count))").tag(1)
                    } else {
                        Text("Transactions (\(accountViewModel.accountTransactionList.count))").tag(1)
                    }
                    Text("Chart").tag(2)
                    Text("WatchLists (\(watchViewModel.watchListForAccount.count))").tag(3)
                }, label: {
                    Text("Account Tab View")
                })
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: tabItem, perform: { _ in
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                })
                if(tabItem == 1) {
                    if(accountViewModel.account.accountType == "Broker") {
                        AccountBrokerView(brokerID: account.id!, accountViewModel: accountViewModel)
                    } else {
                        TransactionsView(accountViewModel: accountViewModel)
                    }
                } else if(tabItem == 2) {
                    AccountChartView(account: account)
                } else {
                    AccountWatchView(watchViewModel: watchViewModel)
                }
            }
            .alert(isPresented: $showZeroAlert) {
                Alert(title: Text("Current Balance should be equal to zero to make it inactive!"))
            }
            .confirmationDialog("Are you sure?",
                                isPresented: $isPresentingAccountDeleteConfirm) {
                Button("Delete account " + account.accountName + "?", role: .destructive) {
                    Task.init {
                        await accountController.deleteAccount(account: account)
                        await accountViewModel.getAccountList()
                        await watchViewModel.getAllWatchList()
                    }
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationTitle(accountViewModel.account.accountName)
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
                Button(action: {
                    self.showAddWatchListView.toggle()
                }, label: {
                    if(watchViewModel.watchListForAccount.count > 1) {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    } else {
                        Image(systemName: "bookmark")
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    }
                })
                .font(.system(size: 14).bold())
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
                                self.failedToMarkInActive = true
                            } else {
                                self.failedToMarkInActive = false
                                if(!initialLoadForActiveButton) {
                                    accountViewModel.account.active = isActive
                                    accountViewModel.account.paymentReminder = false
                                    accountViewModel.account.paymentDate = 0
                                    Task.init {
                                        await accountController.updateAccount(account: accountViewModel.account)
                                        await accountViewModel.getAccountList()
                                    }
                                    NotificationController().removeNotification(id: accountViewModel.account.id!)
                                    paymentDate = 0
                                } else {
                                    initialLoadForActiveButton = false
                                }
                            }
                        } else if(!failedToMarkInActive){
                            accountViewModel.account.active = isActive
                            Task.init {
                                await accountController.updateAccount(account: accountViewModel.account)
                                await accountViewModel.getAccountList()
                            }
                        }
                    })
                    
                    if(isActive) {
                        if(accountViewModel.account.accountType == "Broker") {
                            Button(action: {
                                self.isNewAccountInBrokerViewOpen.toggle()
                            }, label: {
                                Label("New Account", systemImage: "square.and.pencil")
                            })
                        } else {
                            Button(action: {
                                self.isNewTransactionViewOpen.toggle()
                            }, label: {
                                Label("New Transaction", systemImage: "square.and.pencil")
                            })
                        }
                        
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
                                    Task.init {
                                        await accountController.updateAccount(account: accountViewModel.account)
                                        await accountViewModel.getAccountList()
                                    }
                                    NotificationController().enableNotification(account: accountViewModel.account)
                                }
                                .pickerStyle(MenuPickerStyle())
                            } else {
                                Button(action: {
                                    accountViewModel.account.paymentReminder = false
                                    accountViewModel.account.paymentDate = 0
                                    Task.init {
                                        await accountController.updateAccount(account: accountViewModel.account)
                                        await accountViewModel.getAccountList()
                                    }
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
                                    if(!initialLoadForPaymentButton) {
                                        accountViewModel.account.paymentReminder = true
                                        accountViewModel.account.paymentDate = paymentDate
                                        Task.init {
                                            await accountController.updateAccount(account: accountViewModel.account)
                                            await accountViewModel.getAccountList()
                                        }
                                        NotificationController().enableNotification(account: accountViewModel.account)
                                    } else {
                                        initialLoadForPaymentButton = false
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                    }
                    
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
                await accountViewModel.getAccount(id: account.id!)
                paymentDate = accountViewModel.account.paymentDate
                if(accountViewModel.account.paymentReminder) {
                    initialLoadForPaymentButton = true
                }
                isActive = accountViewModel.account.active
                if(!isActive) {
                    initialLoadForActiveButton = true
                }
                if(accountViewModel.account.accountType == "Broker") {
                    await accountViewModel.getAccountInBrokerList(brokerID: account.id!)
                    await accountViewModel.getBrokerAllAccountCurrentBalance(accountBrokerList: accountViewModel.accountsInBroker)
                } else {
                    accountViewModel.getAccountTransactionList(id: account.id!)
                    await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                }
                await watchViewModel.getWatchListByAccount(accountID: account.id!)
            }
        }
        .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
            Task.init {
                await accountViewModel.getAccountList()
                await accountViewModel.getAccount(id: accountViewModel.account.id!)
                accountViewModel.getAccountTransactionList(id: accountViewModel.account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: accountViewModel.account.id!)
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
            }
        }, content: {
            UpdateBalanceAccountView(accountViewModel: accountViewModel)
                .presentationDetents([.medium])
        })
        .sheet(isPresented: $isNewAccountInBrokerViewOpen, onDismiss: {
            Task.init {
                await accountViewModel.getAccountInBrokerList(brokerID: account.id!)
                await accountViewModel.getBrokerAllAccountCurrentBalance(accountBrokerList: accountViewModel.accountsInBroker)
            }
        }, content: {
            NewAccountInBrokerView(brokerAccount: account)
        })
        .sheet(isPresented: $showAddWatchListView, onDismiss: {
            Task.init {
                await watchViewModel.getWatchListByAccount(accountID: account.id!)
                await watchViewModel.getAllWatchList()
            }
        }, content: {
            WatchToAccountView(account: account, watchViewModel: watchViewModel)
        })
        .background(Color.theme.background)
    }
}
