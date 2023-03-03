//
//  SingleWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct SingleWatchListView: View {
    
    var watchList: Watch
    @State private var isNewTransactionViewOpen = false
    @State private var addAccountViewOpen = false
    @State private var isAscending = true
    var watchController = WatchController()
    
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var watchViewModel = WatchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        BalanceCardView(accountViewModel: accountViewModel, accountType: watchList.accountName, isWatchListCardView: true, watchList: watchViewModel.watch)
                            .frame(width: 360)
                            .cornerRadius(10)
                    }
                    .shadow(color: Color.gray, radius: 3)
                    
                    LazyVStack {
                        ForEach(watchViewModel.watch.accountID, id: \.self) { account in
                            AccountRowView(account: Account(id: account))
                                .shadow(color: Color.gray, radius: 3)
                                .contextMenu {
                                    Button(role: .destructive, action: {
                                        watchController.deleteAccountFromWatchList(watchList: watchViewModel.watch, accountID: account)
                                        Task.init {
                                            await watchViewModel.getWatchList(id: watchList.id!)
                                            await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                                            if(!accountViewModel.accountList.isEmpty) {
                                                await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                                            } else {
                                                accountViewModel.totalBalance = BalanceModel(currentValue: 0.0)
                                            }
                                        }
                                    }, label: {
                                        Label("Delete", systemImage: "trash")
                                    })
                                    
                                    Button {
                                        Task.init {
                                            await accountViewModel.getAccount(id: account)
                                        }
                                        isNewTransactionViewOpen.toggle()
                                    } label: {
                                        Label("New Transaction", systemImage: "square.and.pencil")
                                    }
                                }
                        }
                        .padding(10)
                    }
                }
            }
            .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
                Task.init {
                    watchViewModel.watch = Watch()
                    
                    await watchViewModel.getWatchList(id: watchList.id!)
                    await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                }
            }, content: {
                UpdateBalanceAccountView(accountViewModel: accountViewModel)
            })
        }
        .toolbar {
            if(watchList.accountName != "All") {
                ToolbarItem(content: {
                    Button(action: {
                        self.addAccountViewOpen.toggle()
                    }, label: {
                        Image(systemName: "plus")
                    })
                })
            }
            
            ToolbarItem(content: {
                
                Menu(content: {
                    Menu(content: {
                        Button(action: {
                            if(isAscending) {
                                watchViewModel.watch.accountID = accountViewModel
                                    .accountList
                                    .sorted(by: {
                                        $0.accountName > $1.accountName
                                    }).map({
                                        $0.id!
                                    })
                                self.isAscending.toggle()
                            } else {
                                watchViewModel.watch.accountID = accountViewModel
                                    .accountList
                                    .sorted(by: {
                                        $0.accountName < $1.accountName
                                    }).map({
                                        $0.id!
                                    })
                                self.isAscending.toggle()
                            }
                        }, label: {
                            Text("Alphabet")
                        })
                    }, label: {
                        Text("Sort by")
                    })
                }, label: {
                    Image(systemName: "ellipsis")
                })
            })
        }
        .sheet(isPresented: $addAccountViewOpen, onDismiss: {
            Task.init {
                await watchViewModel.getWatchList(id: watchList.id!)
                await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                watchViewModel.watch.accountID = accountViewModel.accountList.sorted(by: {
                    $0.accountName < $1.accountName
                }).map({
                    $0.id!
                })
                if(!watchViewModel.watch.accountID.isEmpty) {
                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                } else {
                    accountViewModel.totalBalance = BalanceModel(currentValue: 0.0)
                }
                
            }
        }) {
            AddAccountWatchListView(watch: watchViewModel.watch)
        }
        .onAppear {
            Task.init {
                await watchViewModel.getWatchList(id: watchList.id!)
                await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                if(!watchViewModel.watch.accountID.isEmpty) {
                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                } else {
                    accountViewModel.totalBalance = BalanceModel(currentValue: 0.0)
                }
                
            }
        }
    }
}
