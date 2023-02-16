//
//  SingleWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct SingleWatchListView: View {
    
    @State var watchList: Watch
    var watchController = WatchController()
    
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject var watchViewModel = WatchViewModel()
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    BalanceCardView(accountViewModel: accountViewModel, accountType: watchList.accountName, isWatchListCardView: true, watchList: watchList)
                        .frame(width: 360)
                        .cornerRadius(10)
                }
                .shadow(color: Color.gray, radius: 3)
                
                LazyVStack {
                    ForEach(watchList.accountID, id: \.self) { account in
                        AccountRowView(account: Account(id: account))
                            .shadow(color: Color.gray, radius: 3)
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    watchController.deleteAccountFromWatchList(watchList: watchList, accountID: account)
                                    Task.init {
                                        await watchViewModel.getWatchList(id: watchList.id!)
                                        self.watchList = watchViewModel.watch
                                        await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                                        await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                                    }
                                }, label: {
                                    Label("Delete", systemImage: "trash")
                                })
                                
                                //                                Button {
                                //                                    Task.init {
                                //                                        let id = watchList.accountID[i]
                                //                                        await accountViewModel.getAccount(id: id)
                                //                                    }
                                //                                    isNewTransactionViewOpen.toggle()
                                //                                } label: {
                                //                                    Label("New Transaction", systemImage: "square.and.pencil")
                                //                                }
                            }
                    }
                    .padding(10)
                }
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountsForWatchList(accountID: watchList.accountID)
                await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
            }
        }
    }
}
