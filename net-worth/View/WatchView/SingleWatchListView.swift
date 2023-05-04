//
//  SingleWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct SingleWatchListView: View {
    
    var watch: Watch
    @State private var isNewTransactionViewOpen = false
    @State private var isAddTransactionHistoryViewOpen = false
    @State private var isChartViewOpen = false
    @State private var addAccountViewOpen = false
    @State private var isAscendingByAlphabet = true
    @State private var isAscendingByAlphabetEnabled = false
    @State private var isAscendingByAmount = true
    @State private var isAscendingByAmountEnabled = false
    var watchController = WatchController()
    
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var watchViewModel = WatchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        BalanceCardView(accountViewModel: accountViewModel, accountType: watch.accountName, isWatchListCardView: true, watchList: watchViewModel.watch)
                            .frame(width: 360)
                            .cornerRadius(10)
                    }
                    .shadow(color: Color.gray, radius: 3)
                    
                    LazyVStack {
                        ForEach(watchViewModel.watch.accountID, id: \.self) { account in
                            NavigationLink(destination: {
                                AccountDetailView(account: Account(id: account), accountViewModel: accountViewModel)
                            }, label: {
                                AccountRowView(account: Account(id: account))
                                    .shadow(color: Color.gray, radius: 3)
                                    .contextMenu {
                                        if(watch.accountName != "All") {
                                            Button(role: .destructive, action: {
                                                watchController.deleteAccountFromWatchList(watchList: watchViewModel.watch, accountID: account)
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
                                                    if(!accountViewModel.accountList.isEmpty) {
                                                        await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                                                    } else {
                                                        accountViewModel.totalBalance = BalanceModel(currentValue: 0.0)
                                                    }
                                                }
                                            }, label: {
                                                Label("Delete", systemImage: "trash")
                                            })
                                        }
                                        
                                        Button {
                                            Task.init {
                                                await accountViewModel.getAccount(id: account)
                                            }
                                            isNewTransactionViewOpen.toggle()
                                        } label: {
                                            Label("New Transaction", systemImage: "square.and.pencil")
                                        }
                                        
                                        Button {
                                            Task.init {
                                                await accountViewModel.getAccount(id: account)
                                            }
                                            isAddTransactionHistoryViewOpen.toggle()
                                        } label: {
                                            Label("Add Transaction History", systemImage: "square.and.pencil")
                                        }
                                    }
                            })
                        }
                        .padding(10)
                    }
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
            .sheet(isPresented: $isAddTransactionHistoryViewOpen, onDismiss: {
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
                AddTransactionHistoryView(accountViewModel: accountViewModel)
            })
        }
        .toolbar {
            if(watch.accountName != "All" && accountViewModel.originalAccountList.count > 0) {
                ToolbarItem(content: {
                    Button(action: {
                        self.addAccountViewOpen.toggle()
                    }, label: {
                        Image(systemName: "plus")
                    })
                })
            }
            
            if(accountViewModel.originalAccountList.count > 0) {
                ToolbarItem(content: {
                    Button(action: {
                        self.isChartViewOpen.toggle()
                    }, label: {
                        Label("Watch Chart", systemImage: "chart.line.uptrend.xyaxis")
                    })
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
                    }, label: {
                        Image(systemName: "ellipsis")
                    })
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
                    accountViewModel.totalBalance = BalanceModel(currentValue: 0.0)
                }
                
            }
        }) {
            AddAccountWatchListView(watch: watchViewModel.watch)
        }
        .sheet(isPresented: $isChartViewOpen, content: {
            ChartView(accountList: accountViewModel.accountList)
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
                    accountViewModel.totalBalance = BalanceModel(currentValue: 0.0)
                }
                
            }
        }
    }
}
