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
    @State var accountTypeSelected = "None"
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
                    Color.theme.background.ignoresSafeArea()
                    VStack {
                        BalanceCardView(accountType: "Net Worth", isWatchListCardView: false, watchList: Watch(), accountViewModel: accountViewModel)
                            .frame(width: 360, height: 70)
                            .cornerRadius(10)
                        Divider()
                        ScrollView(.vertical) {
                            ForEach(accountViewModel.sectionHeaders, id: \.self) { accountType in
                                AccountCardListHeader(accountType: accountType, watchViewModel: watchViewModel)
                                
                                TabView {
                                    ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                                        AccountCard(account: account, isNewTransactionViewOpen: $isNewTransactionViewOpen, isPresentingAccountDeleteConfirm: $isPresentingAccountDeleteConfirm, deletedAccount: $deletedAccount, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                                            .confirmationDialog("Are you sure?",
                                                                isPresented: $isPresentingAccountDeleteConfirm) {
                                                Button("Delete account " + deletedAccount.accountName + "?", role: .destructive) {
                                                    Task.init {
                                                        await accountController.deleteAccount(account: deletedAccount)
                                                        await accountViewModel.getAccountList()
                                                        await watchViewModel.getAllWatchList()
                                                        await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                                                    }
                                                }
                                            }
                                    }
                                }
                                .frame(width: 360, height: 200)
                                .tabViewStyle(.page)
                                .indexViewStyle(.page(backgroundDisplayMode: .always))
                                Divider()
                            }
                        }
                        .refreshable {
                            Task.init {
                                await accountViewModel.getAccountList()
                                await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
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
                        Image(systemName: "plus")
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
            NewAccountView(accountType: "None", accountViewModel: accountViewModel)
        })
    }
}
