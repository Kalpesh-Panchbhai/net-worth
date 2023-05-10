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
    @State private var isChartViewOpen = false
    
    @StateObject var accountViewModel = AccountViewModel()
    
    var accountController = AccountController()
    
    var body: some View {
        ZStack {
            Color.navyBlue.ignoresSafeArea()
            VStack {
                if(!accountType.elementsEqual("Inactive Account")) {
                    VStack {
                        BalanceCardView(accountViewModel: accountViewModel, accountType: accountType, isWatchListCardView: false, watchList: Watch())
                            .frame(width: 360, height: 50)
                            .cornerRadius(10)
                    }
                    .padding(.top, 5)
                    .shadow(color: Color.navyBlue, radius: 3)
                }
                Divider()
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                            NavigationLink(destination: {
                                AccountDetailView(account: account, accountViewModel: accountViewModel)
                            }, label: {
                                AccountRowView(account: account)
                                    .shadow(color: Color.navyBlue, radius: 3)
                                    .contextMenu {
                                        
                                        Label(account.id!, systemImage: "info.square")
                                        
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
                                        
                                        if(account.active) {
                                            Button {
                                                Task.init {
                                                    await accountViewModel.getAccount(id: account.id!)
                                                }
                                                isNewTransactionViewOpen.toggle()
                                            } label: {
                                                Label("New Transaction", systemImage: "square.and.pencil")
                                            }
                                        }
                                    }
                            })
                        }
                        .padding(10)
                    }
                }
                .padding(10)
            }
        }
        .navigationTitle(accountType)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(content: {
                Button(action: {
                    self.isChartViewOpen.toggle()
                }, label: {
                    Label("Account List Chart", systemImage: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Color.lightBlue)
                        .bold()
                })
            })
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
        .sheet(isPresented: $isChartViewOpen, content: {
            AccountWatchListChartView(accountList: accountViewModel.sectionContent(key: accountType, searchKeyword: ""))
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

