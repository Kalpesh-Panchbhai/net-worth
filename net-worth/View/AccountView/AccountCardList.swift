//
//  CardList.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct AccountCardList: View {
    
    var accountController = AccountController()
    
    @State var isNewAccountAccountViewOpen = false
    @State var isNewTransactionViewOpen = false
    @State var accountTypeSelected = ConstantUtils.noneAccountType
    @State var selectedAccount = Account()
    @State var searchText = ""
    @State var isPresentingAccountDeleteConfirm = false
    @State var deletedAccount = Account()
    
    @StateObject var accountViewModel: AccountViewModel
    @ObservedObject var watchViewModel: WatchViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                if(accountViewModel.accountList.isEmpty && accountViewModel.accountListLoaded) {
                    EmptyView(name: "Account")
                } else if (!accountViewModel.accountListLoaded) {
                    LoadingView()
                } else {
                    ZStack {
                        Color.theme.background.ignoresSafeArea()
                        VStack {
                            VStack {
                                BalanceCardView(accountType: "Net Worth", isWatchListCardView: false, watchList: Watch(), accountViewModel: accountViewModel)
                                    .frame(width: 360, height: 70)
                                    .cornerRadius(10)
                            }
                            Divider()
                                .overlay(Color.theme.secondaryText)
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack {
                                    ForEach(accountViewModel.sectionHeaders, id: \.self) { accountType in
                                        if(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 0) {
                                            HStack {
                                                Text(accountType)
                                                    .foregroundColor(Color.theme.primaryText)
                                                    .bold()
                                                    .font(.system(size: 15))
                                                Spacer()
                                                NavigationLink(destination: {
                                                    AccountListView(accountType: accountType, watchViewModel: watchViewModel)
                                                        .toolbarRole(.editor)
                                                }, label: {
                                                    Text("See all")
                                                        .foregroundColor(Color.theme.secondaryText)
                                                        .font(.system(size: 12))
                                                })
                                            }
                                            .padding(.horizontal, 8)
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                LazyHStack {
                                                    ForEach(0..<((accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 5) ? 5 : accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count), id: \.self) { i in
                                                        NavigationLink(destination: {
                                                            AccountDetailView(accountID: (accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i]).id!, accountViewModel:  accountViewModel, watchViewModel: watchViewModel)
                                                                .toolbarRole(.editor)
                                                        }) {
                                                            AccountCardView(accountID: (accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i]).id!)
                                                                .contextMenu {
                                                                    
                                                                    Label(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i].id!, systemImage: ConstantUtils.infoIconImageName)
                                                                    
                                                                    Button(role: .destructive, action: {
                                                                        isPresentingAccountDeleteConfirm.toggle()
                                                                        deletedAccount = accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i];
                                                                    }, label: {
                                                                        Label("Delete", systemImage: ConstantUtils.deleteImageName)
                                                                    })
                                                                    
                                                                    if(accountViewModel.sectionContent(key: accountType, searchKeyword: "")[i].active) {
                                                                        Button {
                                                                            Task.init {
                                                                                await accountViewModel.getAccount(id: accountViewModel.sectionContent(key: accountType, searchKeyword: "")[i].id!)
                                                                            }
                                                                            isNewTransactionViewOpen.toggle()
                                                                        } label: {
                                                                            Label("New Transaction", systemImage: ConstantUtils.newTransactionImageName)
                                                                        }
                                                                    }
                                                                }
                                                        }
                                                        .confirmationDialog("Are you sure?",
                                                                            isPresented: $isPresentingAccountDeleteConfirm) {
                                                            Button("Delete account " + deletedAccount.accountName + "?", role: .destructive) {
                                                                Task.init {
                                                                    deletedAccount.lastUpdated = Date.now
                                                                    deletedAccount.deleted = true
                                                                    await accountController.updateAccount(account: deletedAccount)
                                                                    await ApplicationData.loadData()
                                                                    await accountViewModel.getAccountList()
                                                                    await watchViewModel.getAllWatchList()
                                                                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .padding(5)
                                                }
                                                .padding(5)
                                            }
                                            Divider()
                                                .background(Color.theme.secondaryText)
                                        }
                                    }
                                }
                                .padding(10)
                            }
                            .refreshable {
                                Task.init {
                                    await accountViewModel.getAccountList()
                                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing , content: {
                    Button(action: {
                        isNewAccountAccountViewOpen.toggle()
                    }, label: {
                        Image(systemName: ConstantUtils.plusImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                })
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
            Task.init {
                accountViewModel.accountList = [Account]()
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
            }
        }, content: {
            UpdateBalanceAccountView(accountViewModel: accountViewModel)
                .presentationDetents([.medium])
        })
        .sheet(isPresented: $isNewAccountAccountViewOpen, onDismiss: {
            Task.init {
                await watchViewModel.getAllWatchList()
            }
        }, content: {
            NewAccountView(accountType: ConstantUtils.noneAccountType, accountViewModel: accountViewModel)
        })
    }
}
