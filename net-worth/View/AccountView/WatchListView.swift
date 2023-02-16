//
//  WatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct WatchListView: View {
    
//    init(){
//        UISegmentedControl.appearance().selectedSegmentTintColor = .systemBlue
//    }
    
    @State private var watchList = Watch()
    @State private var newWatchListViewOpen = false
    @State private var updateWatchListViewOpen = false
    @State private var addAccountViewOpen = false
    @State private var isNewTransactionViewOpen = false
    
    @StateObject var watchViewModel = WatchViewModel()
    @StateObject var accountViewModel: AccountViewModel
    @StateObject var financeListViewModel: FinanceListViewModel
    
    var watchController = WatchController()
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("All Watchlists")
                        .bold()
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                    Spacer()
                    if(!(watchList.id?.isEmpty ?? false) && watchViewModel.watchList.count > 1) {
                        Button(action: {
                            WatchController().deleteWatchList(watchList: watchList)
                            Task.init {
                                await watchViewModel.getAllWatchList()
                                if(!watchViewModel.watchList.isEmpty) {
                                    watchList = watchViewModel.watchList[0]
                                } else {
                                    watchList = Watch()
                                }
                            }
                        }, label: {
                            Label("", systemImage: "trash")
                        }).foregroundColor(.red)
                    }
                    
                    if(watchViewModel.watchList.count > 3) {
                        NavigationLink(destination: {
                            AllWatchListView(watchViewModel: watchViewModel)
                        }, label: {
                            Label("See all", systemImage: "")
                        })
                    }
                    if(watchList.accountID.count > 0) {
                        NavigationLink(destination: {
                            SingleWatchListView(watchList: watchList)
                        }, label: {
                            Label("See all", systemImage: "").foregroundColor(.red)
                        })
                    }
                    
                    Button(action: {
                        self.newWatchListViewOpen.toggle()
                    }, label: {
                        Label("", systemImage: "plus")
                    })
                }
                .padding()
                Picker("", selection: $watchList) {
                    ForEach(0..<((watchViewModel.watchList.count > 3) ? 3 : watchViewModel.watchList.count), id: \.self) { i in
                        Text(watchViewModel.watchList[i].accountName).tag(watchViewModel.watchList[i])
                    }
                }
                .pickerStyle(.segmented)
                
                VStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            ForEach(0..<((watchList.accountID.count > 5) ? 5 : watchList.accountID.count), id: \.self) { i in
                                AccountRowView(account: Account(id: watchList.accountID[i]))
                                    .shadow(color: Color.gray, radius: 3)
                                    .contextMenu {
                                        Button(role: .destructive, action: {
                                            watchController.deleteAccountFromWatchList(watchList: watchList, accountID: watchList.accountID[i])
                                            Task.init {
                                                await watchViewModel.getAllWatchList()
                                                if(!watchViewModel.watchList.isEmpty) {
                                                    watchList = watchViewModel.watchList.filter { item in
                                                        item.id == watchList.id
                                                    }.first!
                                                }
                                            }
                                        }, label: {
                                            Label("Delete", systemImage: "trash")
                                        })
                                        
                                        Button {
                                            Task.init {
                                                let id = watchList.accountID[i]
                                                await accountViewModel.getAccount(id: id)
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
                    if(!(watchList.id?.isEmpty ?? false)) {
                        HStack {
                            Button(action: {
                                self.updateWatchListViewOpen.toggle()
                                if(!watchViewModel.watchList.isEmpty) {
                                    watchList = watchViewModel.watchList[0]
                                }
                            }, label: {
                                Label("Edit WatchList", systemImage: "")
                            })
                            Spacer()
                            Button(action: {
                                self.addAccountViewOpen.toggle()
                            }, label: {
                                Label("Add Accounts", systemImage: "")
                            })
                        }
                        .padding()
                    }
                }
            }
        }
        .halfSheet(showSheet: $newWatchListViewOpen) {
            NewWatchView(watchViewModel: watchViewModel)
        }
        .halfSheet(showSheet: $updateWatchListViewOpen) {
            UpdateWatchView(watchList: watchList, watchViewModel: watchViewModel)
        }
        .sheet(isPresented: $addAccountViewOpen, onDismiss: {
            Task.init {
                await watchViewModel.getAllWatchList()
                if(!watchViewModel.watchList.isEmpty) {
                    watchList = watchViewModel.watchList.filter { item in
                        item.id == watchList.id
                    }.first!
                }
            }
        }) {
            AddAccountWatchListView(watch: watchList)
        }
        .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
            Task.init {
                await accountViewModel.getAccount(id: accountViewModel.account.id!)
                await accountViewModel.getAccountTransactionList(id: accountViewModel.account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: accountViewModel.account.id!)
                await financeListViewModel.getSymbolDetails(symbol: accountViewModel.account.symbol)
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
            }
        }, content: {
            UpdateBalanceAccountView(accountViewModel: accountViewModel)
        })
        .onAppear {
            Task.init {
                await watchViewModel.getAllWatchList()
                if(!watchViewModel.watchList.isEmpty) {
                    watchList = watchViewModel.watchList[0]
                }
            }
        }
    }
}
