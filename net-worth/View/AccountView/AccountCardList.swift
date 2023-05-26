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
                    ZStack {
                        Color.navyBlue.ignoresSafeArea()
                        HStack {
                            Text("Click on")
                            Image(systemName: "plus")
                            Text("Icon to add new Account.")
                        }
                        .foregroundColor(Color.lightBlue)
                        .bold()
                    }
                } else if (!accountViewModel.accountListLoaded) {
                    ZStack {
                        Color.navyBlue.ignoresSafeArea()
                        ProgressView().tint(Color.lightBlue)
                    }
                } else {
                    ZStack {
                        Color.navyBlue.ignoresSafeArea()
                        VStack {
                            VStack {
                                BalanceCardView(accountType: "Net Worth", isWatchListCardView: false, watchList: Watch(), accountViewModel: accountViewModel)
                                    .frame(width: 360, height: 50)
                                    .cornerRadius(10)
                            }
                            .shadow(color: Color.navyBlue, radius: 3)
                            Divider()
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack {
                                    ForEach(accountViewModel.sectionHeaders, id: \.self) { accountType in
                                        if(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 0) {
                                            HStack {
                                                Text(accountType.uppercased())
                                                    .foregroundColor(Color.lightBlue)
                                                    .bold()
                                                    .font(.system(size: 15))
                                                Spacer()
                                                NavigationLink(destination: {
                                                    AccountListView(accountType: accountType, watchViewModel: watchViewModel)
                                                        .toolbarRole(.editor)
                                                }, label: {
                                                    Text("See all")
                                                        .foregroundColor(Color.lightBlue)
                                                        .bold()
                                                        .font(.system(size: 15))
                                                })
                                            }
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                LazyHStack {
                                                    ForEach(0..<((accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 5) ? 5 : accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count), id: \.self) { i in
                                                        VStack {
                                                            NavigationLink(destination: {
                                                                AccountDetailView(account: accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i],accountViewModel:  accountViewModel, watchViewModel: watchViewModel)
                                                                    .toolbarRole(.editor)
                                                            }) {
                                                                AccountCardView(account: accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i])
                                                                    .shadow(color: Color.navyBlue, radius: 3)
                                                                    .contextMenu {
                                                                        
                                                                        Label(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i].id!, systemImage: "info.square")
                                                                        
                                                                        Button(role: .destructive, action: {
                                                                            isPresentingAccountDeleteConfirm.toggle()
                                                                            deletedAccount = accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i];
                                                                        }, label: {
                                                                            Label("Delete", systemImage: "trash")
                                                                        })
                                                                        
                                                                        if(accountViewModel.sectionContent(key: accountType, searchKeyword: "")[i].active) {
                                                                            Button {
                                                                                Task.init {
                                                                                    await accountViewModel.getAccount(id: accountViewModel.sectionContent(key: accountType, searchKeyword: "")[i].id!)
                                                                                }
                                                                                isNewTransactionViewOpen.toggle()
                                                                            } label: {
                                                                                Label("New Transaction", systemImage: "square.and.pencil")
                                                                            }
                                                                        }
                                                                    }
                                                            }
                                                        }
                                                        .confirmationDialog("Are you sure?",
                                                                            isPresented: $isPresentingAccountDeleteConfirm) {
                                                            Button("Delete account " + deletedAccount.accountName + "?", role: .destructive) {
                                                                Task.init {
                                                                    try await accountController.deleteAccount(account: deletedAccount)
                                                                    await accountViewModel.getAccountList()
                                                                    await watchViewModel.getAllWatchList()
                                                                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .padding(10)
                                                    
                                                }
                                                .padding(5)
                                            }
                                            Divider()
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
                        Image(systemName: "plus")
                            .foregroundColor(Color.lightBlue)
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
                await accountViewModel.getAccount(id: accountViewModel.account.id!)
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
