//
//  AccountDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailView: View {
    
    var dates = Array(1...28)
    var accountController = AccountController()
    
    @State var showAddWatchListView = false
    @State var isNewTransactionViewOpen = false
    @State var isNewAccountInBrokerViewOpen = false
    @State var isPresentingAccountDeleteConfirm = false
    @State var tabItem = 1
    @State var showZeroAlert = false
    
    @State var accountID: String
    @State var account: Account
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(accountID: String, accountViewModel: AccountViewModel, watchViewModel: WatchViewModel) {
        self.accountID = accountID
        self.account = accountViewModel.accountList.filter {
            return $0.id.elementsEqual(accountID)
        }.first ?? Account()
        self.accountViewModel = accountViewModel
        self.watchViewModel = watchViewModel
        
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.theme.primaryText)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.theme.background)], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.theme.primaryText)], for: .normal)
    }
    
    var body: some View {
        VStack {
            VStack {
                AccountDetailCardView(account: account)
                    .cornerRadius(10)
                Picker(selection: $tabItem, content: {
                    if(account.accountType == ConstantUtils.brokerAccountType) {
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
                    if(account.accountType == ConstantUtils.brokerAccountType) {
                        AccountBrokerView(brokerID: accountID, accountViewModel: accountViewModel)
                    } else {
                        TransactionsView(account: account, accountTransactionList: accountViewModel.accountTransactionList)
                    }
                } 
                else if(tabItem == 2) {
                    if(account.accountType == ConstantUtils.brokerAccountType) {
                        AccountBrokerChartView(brokerID: accountViewModel.account.id, accountID: "", symbol: "", accountViewModel: accountViewModel)
                    } else {
                        AccountChartView(accountID: accountID, accountViewModel: accountViewModel)
                    }
                } else {
                    AccountWatchView(watchViewModel: watchViewModel, accountViewModel: accountViewModel)
                }
            }
            .alert(isPresented: $showZeroAlert) {
                Alert(title: Text("Current Balance should be equal to zero to make it inactive!"))
            }
            .confirmationDialog("Are you sure?",
                                isPresented: $isPresentingAccountDeleteConfirm) {
                Button("Delete account " + account.accountName + "?", role: .destructive) {
                    Task.init {
                        await accountController.deleteAccount(accountId: accountID)
                        await accountViewModel.getAccountList()
                        await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                        await watchViewModel.getAllWatchList()
                    }
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
                    
                    if(account.active) {
                        if(account.accountType == ConstantUtils.brokerAccountType) {
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
                        
                        if(account.balance.currentDayValue.isZero) {
                            Button(action: {
                                Task.init {
                                    var updatedAccount = self.account
                                    updatedAccount.active = false
                                    await accountController.updateAccount(account: updatedAccount)
                                    await accountViewModel.getAccountList()
                                    account = accountViewModel.accountList.filter {
                                        return $0.id.elementsEqual(accountID)
                                    }.first ?? Account()
                                }
                            }, label: {
                                Label("Close account", systemImage: ConstantUtils.newTransactionImageName)
                            })
                        }
                    } else {
                        Button(action: {
                            Task.init {
                                var updatedAccount = self.account
                                updatedAccount.active = true
                                await accountController.updateAccount(account: updatedAccount)
                                await accountViewModel.getAccountList()
                                self.account = accountViewModel.accountList.filter {
                                    return $0.id.elementsEqual(accountID)
                                }.first ?? Account()
                            }
                        }, label: {
                            Label("Open account", systemImage: ConstantUtils.newTransactionImageName)
                        })
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
                if(account.accountType.elementsEqual(ConstantUtils.brokerAccountType)) {
                    await accountViewModel.getAccountInBrokerList(brokerID: accountID)
                } else {
                    await accountViewModel.getAccountTransactionList(id: accountID)
                }
                await watchViewModel.getWatchListByAccount(accountID: accountID)
            }
        }
        .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
            self.account = accountViewModel.accountList.filter {
                return $0.id.elementsEqual(accountID)
            }.first ?? Account()
        }, content: {
            UpdateBalanceAccountView(accountId: accountID, accountViewModel: accountViewModel)
                .presentationDetents([.medium])
        })
        .sheet(isPresented: $isNewAccountInBrokerViewOpen, onDismiss: {
            
        }, content: {
            NewAccountInBrokerView(brokerAccountID: accountID, accountViewModel: accountViewModel)
        })
        .sheet(isPresented: $showAddWatchListView, onDismiss: {
            Task.init {
                await watchViewModel.getWatchListByAccount(accountID: accountID)
            }
        }, content: {
            WatchToAccountView(accountID: accountID, watchViewModel: watchViewModel)
        })
        .background(Color.theme.background)
    }
}
