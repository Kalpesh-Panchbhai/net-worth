//
//  AccountDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailView: View {
    
    var dates = Array(1...28)
    var accountID: String
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
    
    init(accountID: String, accountViewModel: AccountViewModel, watchViewModel: WatchViewModel) {
        self.accountID = accountID
        self.accountViewModel = accountViewModel
        self.watchViewModel = watchViewModel
        
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.theme.primaryText)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.theme.background)], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.theme.primaryText)], for: .normal)
    }
    
    var body: some View {
        VStack {
            VStack {
                if(accountViewModel.account.accountType == ConstantUtils.brokerAccountType) {
                    AccountBrokerDetailCardView(accountViewModel: accountViewModel)
                        .cornerRadius(10)
                } else {
                    AccountDetailCardView(accountViewModel: accountViewModel)
                        .cornerRadius(10)
                }
                Picker(selection: $tabItem, content: {
                    if(accountViewModel.account.accountType == ConstantUtils.brokerAccountType) {
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
                    if(accountViewModel.account.accountType == ConstantUtils.brokerAccountType) {
                        AccountBrokerView(brokerID: accountID, accountViewModel: accountViewModel)
                    } else {
                        TransactionsView(accountViewModel: accountViewModel)
                    }
                } else if(tabItem == 2) {
                    if(accountViewModel.account.accountType == ConstantUtils.brokerAccountType) {
                        AccountBrokerChartView(brokerID: accountViewModel.account.id!, accountID: "", symbol: "")
                    } else {
                        AccountChartView(accountID: accountID)
                    }
                } else {
                    AccountWatchView(watchViewModel: watchViewModel)
                }
            }
            .alert(isPresented: $showZeroAlert) {
                Alert(title: Text("Current Balance should be equal to zero to make it inactive!"))
            }
            .confirmationDialog("Are you sure?",
                                isPresented: $isPresentingAccountDeleteConfirm) {
                Button("Delete account " + accountViewModel.account.accountName + "?", role: .destructive) {
                    Task.init {
                        await accountController.deleteAccount(accountID: accountID, isBrokerAccount: accountViewModel.account.accountType == ConstantUtils.brokerAccountType)
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
                Image(systemName: ConstantUtils.backbuttonImageName)
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
                        Image(systemName: ConstantUtils.bookmarkImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    } else {
                        Image(systemName: ConstantUtils.notBookmarkImageName)
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
                        Label("Delete", systemImage: ConstantUtils.deleteImageName)
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
                        if(accountViewModel.account.accountType == ConstantUtils.brokerAccountType) {
                            Button(action: {
                                self.isNewAccountInBrokerViewOpen.toggle()
                            }, label: {
                                Label("New Account", systemImage: ConstantUtils.newTransactionImageName)
                            })
                        } else {
                            Button(action: {
                                self.isNewTransactionViewOpen.toggle()
                            }, label: {
                                Label("New Transaction", systemImage: ConstantUtils.newTransactionImageName)
                            })
                        }
                        
                        if(accountViewModel.account.accountType != ConstantUtils.savingAccountType) {
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
                    Image(systemName: ConstantUtils.menuImageName)
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                })
                .font(.system(size: 14).bold())
            })
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccount(id: accountID)
                paymentDate = accountViewModel.account.paymentDate
                if(accountViewModel.account.paymentReminder) {
                    initialLoadForPaymentButton = true
                }
                isActive = accountViewModel.account.active
                if(!isActive) {
                    initialLoadForActiveButton = true
                }
                if(accountViewModel.account.accountType == ConstantUtils.brokerAccountType) {
                    await accountViewModel.getAccountInBrokerList(brokerID: accountID)
                    await accountViewModel.getCurrentBalanceOfAllAccountsInABroker(accountBrokerList: accountViewModel.accountsInBroker)
                } else {
                    accountViewModel.getAccountTransactionList(id: accountID)
                    await accountViewModel.getLastTwoAccountTransactionList(id: accountID)
                }
                await watchViewModel.getWatchListByAccount(accountID: accountID)
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
                await accountViewModel.getAccountInBrokerList(brokerID: accountID)
                await accountViewModel.getCurrentBalanceOfAllAccountsInABroker(accountBrokerList: accountViewModel.accountsInBroker)
            }
        }, content: {
            NewAccountInBrokerView(brokerAccountID: accountID)
        })
        .sheet(isPresented: $showAddWatchListView, onDismiss: {
            Task.init {
                await watchViewModel.getWatchListByAccount(accountID: accountID)
                await watchViewModel.getAllWatchList()
            }
        }, content: {
            WatchToAccountView(accountID: accountID, watchViewModel: watchViewModel)
        })
        .background(Color.theme.background)
    }
}
