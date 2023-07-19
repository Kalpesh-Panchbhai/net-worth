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
    @State var isPresentingAccountDeleteConfirm = false
    @State var deletedAccount = Account()
    
    @StateObject var accountViewModel = AccountViewModel()
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack {
                if(!accountType.elementsEqual("Inactive Account") && !accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).isEmpty) {
                    VStack {
                        BalanceCardView(accountType: accountType, isWatchListCardView: false, watchList: Watch(), accountViewModel: accountViewModel)
                            .frame(width: 360, height: 70)
                            .cornerRadius(10)
                    }
                }
                Divider()
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                            NavigationLink(destination: {
                                AccountDetailView(account: account, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                            }, label: {
                                AccountRowView(account: account, fromWatchView: accountType.elementsEqual("Inactive Account"))
                                    .contextMenu {
                                        
                                        Label(account.id!, systemImage: "info.square")
                                        
                                        Button(role: .destructive, action: {
                                            isPresentingAccountDeleteConfirm.toggle()
                                            deletedAccount = account
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
                    .foregroundColor(Color.theme.primaryText)
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
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                })
                .font(.system(size: 14).bold())
            })
        }
        .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
            Task.init {
                await accountViewModel.getAccount(id: accountViewModel.account.id!)
                accountViewModel.getAccountTransactionList(id: accountViewModel.account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: accountViewModel.account.id!)
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance(accountList: accountViewModel.sectionContent(key: accountType, searchKeyword: ""))
            }
        }, content: {
            UpdateBalanceAccountView(accountViewModel: accountViewModel)
                .presentationDetents([.medium])
        })
        .sheet(isPresented: $isChartViewOpen, content: {
            AccountWatchChartView(accountList: accountViewModel.sectionContent(key: accountType, searchKeyword: ""))
        })
        .confirmationDialog("Are you sure?",
                            isPresented: $isPresentingAccountDeleteConfirm) {
            Button("Delete account " + deletedAccount.accountName + "?", role: .destructive) {
                Task.init {
                    await accountController.deleteAccount(account: deletedAccount)
                    await accountViewModel.getAccountList()
                    await watchViewModel.getAllWatchList()
                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .searchable(text: $searchText)
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
            }
        }
    }
}

