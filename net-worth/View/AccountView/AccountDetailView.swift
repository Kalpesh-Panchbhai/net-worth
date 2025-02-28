//
//  AccountDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailView: View {
    
    var accountController = AccountController()
    
    @State var showAddWatchListView = false
    @State var isNewTransactionViewOpen = false
    @State var isNewAccountInBrokerViewOpen = false
    @State var isPresentingAccountDeleteConfirm = false
    @State var tabItem = 1
    @State var sortOrder = "Asc"
    @State var sortType = "Name"
    
    @State var accountID: Int
    @State var account = AccountRestModel()
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var watchViewModel: WatchViewModel
    @EnvironmentObject var watchAccountViewModel: WatchAccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(accountID: Int) {
        self.accountID = accountID
        
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
                    if(account.type == ConstantUtils.brokerAccountType) {
                        Text("Accounts (\(accountViewModel.accountsInBroker.count))").tag(1)
                        Text("Chart").tag(2)
                        Text("WatchLists (\(watchAccountViewModel.allWatchListByAccountID.count))").tag(3)
                    } else {
                        Text("Transactions (\(accountViewModel.accountTransactionList.count))").tag(1)
                        Text("Chart").tag(2)
                        Text("WatchLists (\(watchAccountViewModel.allWatchListByAccountID.count))").tag(3)
                    }
                }, label: {
                    Text("Account Tab View")
                })
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: tabItem) {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
                if(account.type == ConstantUtils.brokerAccountType) {
                    if(tabItem == 1) {
                        AccountBrokerView(brokerID: accountID, sortOrder: $sortOrder, sortType: $sortType)
                    } else if(tabItem == 2) {
                        AccountChartView(id: accountID, type: "one_broker")
                    } else {
                        AccountWatchView()
                    }
                } else {
                    if(tabItem == 1) {
                        AccountTransactionView(id: accountID, type: "account")
                    } else if(tabItem == 2) {
                        AccountChartView(id: accountID, type: "one_non_broker")
                    } else {
                        AccountWatchView()
                    }
                }
            }
            .confirmationDialog("Are you sure?",
                                isPresented: $isPresentingAccountDeleteConfirm) {
                Button("Delete account " + account.name + "?", role: .destructive) {
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
        .navigationTitle(account.name)
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
                    if(watchAccountViewModel.allWatchListByAccountID.count > 1) {
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
                        if(account.type == ConstantUtils.brokerAccountType) {
                            Button(action: {
                                self.isNewAccountInBrokerViewOpen.toggle()
                            }, label: {
                                Label("New Account", systemImage: ConstantUtils.newTransactionImageName)
                            })
                            if(accountViewModel.accountsInBroker.count > 1) {
                                Menu(content: {
                                    Button(action: {
                                        sortType = "Name"
                                    }, label: {
                                        if(sortType.elementsEqual("Name")) {
                                            Label("Name", systemImage: "checkmark")
                                        } else {
                                            Text("Name")
                                        }
                                    })
                                    
                                    Button(action: {
                                        sortType = "Amount"
                                    }, label: {
                                        if(sortType.elementsEqual("Amount")){
                                            Label("Amount", systemImage: "checkmark")
                                        } else {
                                            Text("Amount")
                                        }
                                    })
                                    
                                    Button(action: {
                                        sortType = "Price Change"
                                    }, label: {
                                        if(sortType.elementsEqual("Price Change")){
                                            Label("Price Change", systemImage: "checkmark")
                                        } else {
                                            Text("Price Change")
                                        }
                                    })
                                    
                                    Button(action: {
                                        sortType = "Percentage Change"
                                    }, label: {
                                        if(sortType.elementsEqual("Percentage Change")){
                                            Label("Percentage Change", systemImage: "checkmark")
                                        } else {
                                            Text("Percentage Change")
                                        }
                                    })
                                    
                                    Divider()
                                    
                                    Button(action: {
                                        sortOrder = "Asc"
                                    }, label: {
                                        if(sortOrder.elementsEqual("Asc")){
                                            Label("Ascending", systemImage: "checkmark")
                                        } else {
                                            Text("Ascending")
                                        }
                                    })
                                    
                                    Button(action: {
                                        sortOrder = "Desc"
                                    }, label: {
                                        if(sortOrder.elementsEqual("Desc")){
                                            Label("Descending", systemImage: "checkmark")
                                        } else {
                                            Text("Descending")
                                        }
                                    })
                                    
                                }, label: {
                                    Text("Sort Account By")
                                    Text(sortType + "," + sortOrder)
                                })
                            }
                        } else {
                            Button(action: {
                                self.isNewTransactionViewOpen.toggle()
                            }, label: {
                                Label("New Transaction", systemImage: ConstantUtils.newTransactionImageName)
                            })
                        }
                        
                        if(account.value.currentValue.isZero) {
                            Button(action: {
                                Task.init {
                                    var updatedAccount = self.account
                                    updatedAccount.active = false
                                    await accountController.updateAccount(account: updatedAccount)
                                    await accountViewModel.getAccountList()
                                    account = accountViewModel.accountList.filter {
                                        return $0.id == accountID
                                    }.first ?? AccountRestModel()
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
                                    return $0.id == accountID
                                }.first ?? AccountRestModel()
                            }
                        }, label: {
                            Label("Open account", systemImage: ConstantUtils.newTransactionImageName)
                        })
                    }
                    
                }, label: {
                    ZStack {
                        Circle()
                            .frame(width: 25, height: 25)
                            .foregroundColor(ColorTheme().green)
                        Image(systemName: ConstantUtils.menuImageName)
                            .foregroundColor(Color.theme.background)
                            .font(.system(size: 12))
                    }
                })
                .font(.system(size: 14))
            })
        }
        .onAppear {
            Task.init {
                self.account = accountViewModel.accountList.filter {
                    return $0.id == accountID
                }.first ?? AccountRestModel()
                if(account.type.elementsEqual(ConstantUtils.brokerAccountType)) {
                    await accountViewModel.getAccountInBrokerList(brokerID: accountID)
                } else {
                    await accountViewModel.getAccountTransactionList(accountID: accountID, type: "account")
                }
                await watchAccountViewModel.getAllWatchListByAccountID(accountID: accountID)
            }
        }
        .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
            self.account = accountViewModel.accountList.filter {
                return $0.id == accountID
            }.first ?? AccountRestModel()
            Task.init {
                await accountViewModel.getAccountTransactionList(accountID: accountID, type: "account")
            }
        }, content: {
            UpdateBalanceAccountView(accountId: accountID)
                .presentationDetents([.medium])
        })
        .sheet(isPresented: $isNewAccountInBrokerViewOpen, onDismiss: {
            
        }, content: {
            NewAccountInBrokerView(brokerAccountID: accountID)
        })
        .sheet(isPresented: $showAddWatchListView, onDismiss: {
            Task.init {
                await watchAccountViewModel.getAllWatchListByAccountID(accountID: accountID)
                await watchViewModel.getAllWatchList()
            }
        }, content: {
            WatchToAccountView(accountID: accountID)
        })
        .background(Color.theme.background)
    }
}
