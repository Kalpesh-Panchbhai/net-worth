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
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(account: Account, accountViewModel: AccountViewModel, watchViewModel: WatchViewModel) {
        self.account = account
        self.accountViewModel = accountViewModel
        self.watchViewModel = watchViewModel
        
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(red: 0.3490196078, green: 0.7411764706, blue: 0.9568627451, alpha: 1)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(red: 0.9058823529, green: 0.9490196078, blue: 0.9803921569, alpha: 1)], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(red: 0.3490196078, green: 0.7411764706, blue: 0.9568627451, alpha: 1)], for: .normal)
    }
    
    var body: some View {
        VStack {
            VStack {
                AccountDetailCardView(accountViewModel: accountViewModel)
                    .cornerRadius(10)
                    .shadow(color: Color.navyBlue, radius: 3)
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
                    .foregroundColor(Color.lightBlue)
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
                            .foregroundColor(Color.lightBlue)
                            .bold()
                    } else {
                        Image(systemName: "bookmark")
                            .foregroundColor(Color.lightBlue)
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
                        .foregroundColor(Color.lightBlue)
                        .bold()
                })
                .font(.system(size: 14).bold())
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
                .presentationDetents([.medium])
        })
        .sheet(isPresented: $showAddWatchListView, onDismiss: {
            Task.init {
                await watchViewModel.getWatchListByAccount(accountID: account.id!)
                await watchViewModel.getAllWatchList()
            }
        }, content: {
            AddWatchListToAccountView(watchViewModel: watchViewModel, account: account)
        })
        .background(Color.navyBlue)
    }
}
