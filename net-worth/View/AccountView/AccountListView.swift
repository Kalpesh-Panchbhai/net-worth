//
//  AccountListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountListView: View {
    
    var accountType: String
    var accountController = AccountController()
    
    @State var searchText = ""
    @State var isNewTransactionViewOpen = false
    @State var isChartViewOpen = false
    
    @StateObject var accountViewModel = AccountViewModel()
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.navyBlue.ignoresSafeArea()
            VStack {
                if(!accountType.elementsEqual("Inactive Account") && !accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).isEmpty) {
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
                                AccountDetailView(account: account, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
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
                                                await watchViewModel.getAllWatchList()
                                            }
                                            self.presentationMode.wrappedValue.dismiss()
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
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.lightBlue)
                    .bold()
            }
                .font(.system(size: 14).bold())
        )
        .toolbar {
            ToolbarItem(content: {
                Button(action: {
                    self.isChartViewOpen.toggle()
                }, label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Color.lightBlue)
                        .bold()
                })
                .font(.system(size: 14).bold())
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
                .presentationDetents([.medium])
        })
        .sheet(isPresented: $isChartViewOpen, content: {
            AccountWatchListChartView(accountList: accountViewModel.sectionContent(key: accountType, searchKeyword: ""))
                .presentationDetents([.medium])
        })
        .searchable(text: $searchText)
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
            }
        }
    }
}

