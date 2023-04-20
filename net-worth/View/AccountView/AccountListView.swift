//
//  AccountListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountListView: View {
    
    var accountType: String
    
    @State private var searchText = ""
    @State private var isNewTransactionViewOpen = false
    
    @StateObject var accountViewModel = AccountViewModel()
    
    var accountController = AccountController()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    BalanceCardView(accountViewModel: accountViewModel, accountType: accountType, isWatchListCardView: false, watchList: Watch())
                        .frame(width: 360)
                        .cornerRadius(10)
                }
                .padding(.top, 5)
                .shadow(color: Color.gray, radius: 3)
                LazyVStack {
                    ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                        NavigationLink(destination: {
                            AccountDetailView(account: account, accountViewModel: accountViewModel)
                        }, label: {
                            AccountRowView(account: account)
                                .shadow(color: Color.gray, radius: 3)
                                .contextMenu {
                                    Button(role: .destructive, action: {
                                        Task.init {
                                            try await accountController.deleteAccount(account: account)
                                        }
                                        Task.init {
                                            await accountViewModel.getAccountList()
                                            await accountViewModel.getTotalBalance(accountList: accountViewModel.sectionContent(key: accountType, searchKeyword: ""))
                                        }
                                    }, label: {
                                        Label("Delete", systemImage: "trash")
                                    })
                                    
                                    Button {
                                        Task.init {
                                            await accountViewModel.getAccount(id: account.id!)
                                        }
                                        isNewTransactionViewOpen.toggle()
                                    } label: {
                                        Label("New Transaction", systemImage: "square.and.pencil")
                                    }
                                }
                            Divider()
                        })
                    }
                    .padding(10)
                }
            }
            .padding(10)
        }
        .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
            Task.init {
                await accountViewModel.getAccount(id: accountViewModel.account.id!)
                await accountViewModel.getAccountTransactionList(id: accountViewModel.account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: accountViewModel.account.id!)
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance(accountList: accountViewModel.sectionContent(key: accountType, searchKeyword: ""))
            }
        }, content: {
            UpdateBalanceAccountView(accountViewModel: accountViewModel)
        })
        .searchable(text: $searchText)
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
            }
        }
        .background(Color.gray)
    }
}

