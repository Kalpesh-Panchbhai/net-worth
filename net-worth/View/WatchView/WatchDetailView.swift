//
//  SingleWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct WatchDetailView: View {
    
    var watch: Watch
    var watchController = WatchController()
    
    @State var isNewTransactionViewOpen = false
    @State var isChartViewOpen = false
    @State var addAccountViewOpen = false
    @State var isAscendingByAlphabet = true
    @State var isAscendingByAlphabetEnabled = false
    @State var isAscendingByAmount = true
    @State var isAscendingByAmountEnabled = false
    @State var hideInactiveAccount = true
    
    @StateObject var accountViewModel = AccountViewModel()
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                VStack {
                    if(watchViewModel.watch.accountID.count > 0) {
                        // MARK: Balance Card
                        VStack {
                            BalanceCardView(accountType: watch.accountName, isWatchListCardView: true, watchList: watchViewModel.watch, accountViewModel: accountViewModel)
                                .frame(width: 360, height: 70)
                                .cornerRadius(10)
                        }
                        .padding(.top, 5)
                        Divider()
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack {
                                ForEach(watchViewModel.watch.accountID, id: \.self) { accountID in
                                    if((hideInactiveAccount && isAccountActive(id: accountID)) || !hideInactiveAccount) {
                                        NavigationLink(destination: {
                                            // MARK: Account Detail View
                                            AccountDetailView(accountID: accountID, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                                                .toolbarRole(.editor)
                                        }, label: {
                                            AccountRowView(accountID: accountID, fromWatchView: true)
                                                .contextMenu {
                                                    Label(accountID, systemImage: ConstantUtils.infoIconImageName)
                                                    // MARK: Delete
                                                    if(watch.accountName != "All") {
                                                        Button(role: .destructive, action: {
                                                            watchController.deleteAccountFromWatchList(watchList: watchViewModel.watch, accountID: accountID)
                                                            Task.init {
                                                                await watchViewModel.getAllWatchList()
                                                                await watchViewModel.getWatchList(id: watch.id!)
                                                                await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                                                                if(isAscendingByAlphabetEnabled) {
                                                                    if(isAscendingByAlphabet) {
                                                                        watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                                                                            $0.accountName < $1.accountName
                                                                        }).map({
                                                                            $0.id!
                                                                        })
                                                                    } else {
                                                                        watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                                                                            $0.accountName > $1.accountName
                                                                        }).map({
                                                                            $0.id!
                                                                        })
                                                                    }
                                                                    self.isAscendingByAmountEnabled = false
                                                                } else if(isAscendingByAmountEnabled) {
                                                                    if(isAscendingByAmount) {
                                                                        watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                                                                            $0.currentBalance < $1.currentBalance
                                                                        }).map({
                                                                            $0.id!
                                                                        })
                                                                    } else {
                                                                        watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                                                                            $0.currentBalance > $1.currentBalance
                                                                        }).map({
                                                                            $0.id!
                                                                        })
                                                                    }
                                                                    self.isAscendingByAlphabetEnabled = false
                                                                }
                                                                if(!accountViewModel.accountList.isEmpty) {
                                                                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                                                                } else {
                                                                    accountViewModel.totalBalance = Balance(currentValue: 0.0)
                                                                }
                                                            }
                                                        }, label: {
                                                            Label("Delete", systemImage: ConstantUtils.deleteImageName)
                                                        })
                                                    }
                                                    
                                                    if(isAccountActive(id: accountID)) {
                                                        // MARK: New Transaction
                                                        Button {
                                                            Task.init {
                                                                await accountViewModel.getAccount(id: accountID)
                                                            }
                                                            isNewTransactionViewOpen.toggle()
                                                        } label: {
                                                            Label("New Transaction", systemImage: ConstantUtils.newTransactionImageName)
                                                        }
                                                    }
                                                }
                                        })
                                    }
                                }
                                .padding(10)
                            }
                        }
                        .padding(10)
                    }
                }
                .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
                    Task.init {
                        watchViewModel.watch = Watch()
                        
                        await watchViewModel.getWatchList(id: watch.id!)
                        await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                        if(isAscendingByAlphabetEnabled) {
                            if(isAscendingByAlphabet) {
                                watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                                    $0.accountName < $1.accountName
                                }).map({
                                    $0.id!
                                })
                            } else {
                                watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                                    $0.accountName > $1.accountName
                                }).map({
                                    $0.id!
                                })
                            }
                            self.isAscendingByAmountEnabled = false
                        } else if(isAscendingByAmountEnabled) {
                            if(isAscendingByAmount) {
                                watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                                    $0.currentBalance < $1.currentBalance
                                }).map({
                                    $0.id!
                                })
                            } else {
                                watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                                    $0.currentBalance > $1.currentBalance
                                }).map({
                                    $0.id!
                                })
                            }
                            self.isAscendingByAlphabetEnabled = false
                        }
                        await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                    }
                }, content: {
                    UpdateBalanceAccountView(accountViewModel: accountViewModel)
                })
            }
        }
        .navigationTitle(watch.accountName)
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
            if(watch.accountName != "All" && accountViewModel.originalAccountList.count > 0) {
                ToolbarItem(content: {
                    Button(action: {
                        self.addAccountViewOpen.toggle()
                    }, label: {
                        Image(systemName: ConstantUtils.plusImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                })
            }
            
            if(accountViewModel.originalAccountList.count > 0) {
                ToolbarItem(content: {
                    Button(action: {
                        self.isChartViewOpen.toggle()
                    }, label: {
                        Image(systemName: ConstantUtils.chartImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                })
            }
            
            if(watchViewModel.watch.accountID.count > 1) {
                ToolbarItem(content: {
                    
                    Menu(content: {
                        Menu(content: {
                            Button(action: {
                                if(isAscendingByAlphabet) {
                                    watchViewModel.watch.accountID = accountViewModel
                                        .accountList
                                        .sorted(by: {
                                            $0.accountName > $1.accountName
                                        }).map({
                                            $0.id!
                                        })
                                    self.isAscendingByAlphabet.toggle()
                                    self.isAscendingByAlphabetEnabled = true
                                    self.isAscendingByAmountEnabled = false
                                } else {
                                    watchViewModel.watch.accountID = accountViewModel
                                        .accountList
                                        .sorted(by: {
                                            $0.accountName < $1.accountName
                                        }).map({
                                            $0.id!
                                        })
                                    self.isAscendingByAlphabet.toggle()
                                    self.isAscendingByAlphabetEnabled = true
                                    self.isAscendingByAmountEnabled = false
                                }
                            }, label: {
                                Text("Alphabet")
                            })
                            
                            Button(action: {
                                if(isAscendingByAmount) {
                                    watchViewModel.watch.accountID = accountViewModel
                                        .accountList
                                        .sorted(by: {
                                            $0.currentBalance > $1.currentBalance
                                        }).map({
                                            $0.id!
                                        })
                                    self.isAscendingByAmount.toggle()
                                    self.isAscendingByAmountEnabled = true
                                    self.isAscendingByAlphabetEnabled = false
                                } else {
                                    watchViewModel.watch.accountID = accountViewModel
                                        .accountList
                                        .sorted(by: {
                                            $0.currentBalance < $1.currentBalance
                                        }).map({
                                            $0.id!
                                        })
                                    self.isAscendingByAmount.toggle()
                                    self.isAscendingByAmountEnabled = true
                                    self.isAscendingByAlphabetEnabled = false
                                }
                            }, label: {
                                Text("Amount")
                            })
                        }, label: {
                            Text("Sort by")
                        })
                        
                        Toggle(isOn: $hideInactiveAccount, label: {
                            Text("Hide Inactive Accounts")
                        })
                    }, label: {
                        Image(systemName: ConstantUtils.menuImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                })
            }
        }
        .sheet(isPresented: $addAccountViewOpen, onDismiss: {
            Task.init {
                await watchViewModel.getWatchList(id: watch.id!)
                await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                if(isAscendingByAlphabetEnabled) {
                    if(isAscendingByAlphabet) {
                        watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                            $0.accountName < $1.accountName
                        }).map({
                            $0.id!
                        })
                    } else {
                        watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                            $0.accountName > $1.accountName
                        }).map({
                            $0.id!
                        })
                    }
                    self.isAscendingByAmountEnabled = false
                } else if(isAscendingByAmountEnabled) {
                    if(isAscendingByAmount) {
                        watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                            $0.currentBalance < $1.currentBalance
                        }).map({
                            $0.id!
                        })
                    } else {
                        watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                            $0.currentBalance > $1.currentBalance
                        }).map({
                            $0.id!
                        })
                    }
                    self.isAscendingByAlphabetEnabled = false
                }
                if(!watchViewModel.watch.accountID.isEmpty) {
                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                } else {
                    accountViewModel.totalBalance = Balance(currentValue: 0.0)
                }
                
            }
        }) {
            AccountToWatchView(watch: watchViewModel.watch)
        }
        .sheet(isPresented: $isChartViewOpen, content: {
            AccountWatchChartView(id: watch.id!, accountList: accountViewModel.accountList)
        })
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
                await watchViewModel.getWatchList(id: watch.id!)
                await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                    $0.accountName < $1.accountName
                }).map({
                    $0.id!
                })
                self.isAscendingByAlphabetEnabled.toggle()
                if(!watchViewModel.watch.accountID.isEmpty) {
                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                } else {
                    accountViewModel.totalBalance = Balance(currentValue: 0.0)
                }
                
            }
        }
    }
    
    private func isAccountActive(id: String) -> Bool {
        return ApplicationData.shared.data.accountDataList.filter {
            $0.account.id!.elementsEqual(id) && $0.account.active
        }.count > 0
    }
}
