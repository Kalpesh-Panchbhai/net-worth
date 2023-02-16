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
    var watchController = WatchController()
    
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject var watchViewModel = WatchViewModel()
    
    var body: some View {
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
        .onAppear {
            Task.init {
                await watchViewModel.getWatchList(id: watchList.id!)
                await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
            }
        }
    }
}
