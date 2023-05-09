//
//  CardList.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct AccountCardList: View {
    
    @State private var isNewAccountAccountViewOpen = false
    @State private var isNewTransactionViewOpen = false
    @State private var accountTypeSelected = "None"
    @State private var selectedAccount = Account()
    @State private var searchText = ""
    @State private var isPresentingAccountDeleteConfirm = false
    
    @StateObject var accountViewModel: AccountViewModel
    @ObservedObject var watchViewModel: WatchViewModel
    
    var accountController = AccountController()
    
    @State private var deletedAccount = Account()
    
    var body: some View {
        NavigationView {
            ZStack {
                if(accountViewModel.accountList.isEmpty) {
                    ZStack {
                        HStack {
                            Text("Click on")
                            Image(systemName: "plus")
                            Text("Icon to add new Account.")
                        }
                    }
                } else {
                    ZStack {
                        Color.black
                        VStack {
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack {
                                    BalanceCardView(accountViewModel: accountViewModel, accountType: "Net Worth", isWatchListCardView: false, watchList: Watch())
                                        .frame(width: 360)
                                        .cornerRadius(10)
                                }
                                .shadow(color: Color.gray, radius: 3)
                                
                                LazyVStack {
                                    ForEach(accountViewModel.sectionHeaders, id: \.self) { accountType in
                                        if(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 0) {
                                            HStack {
                                                Text(accountType.uppercased())
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 15))
                                                Spacer()
                                                NavigationLink(destination: {
                                                    AccountListView(accountType: accountType)
                                                        .toolbarRole(.editor)
                                                }, label: {
                                                    Text("See all")
                                                        .foregroundColor(.green)
                                                        .bold()
                                                        .font(.system(size: 15))
                                                })
                                            }
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                LazyHStack {
                                                    ForEach(0..<((accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 5) ? 5 : accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count), id: \.self) { i in
                                                        VStack {
                                                            NavigationLink(destination: {
                                                                AccountDetailView(account: accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i],accountViewModel:  accountViewModel)
                                                                    .toolbarRole(.editor)
                                                            }) {
                                                                AccountCardView(account: accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i])
                                                                    .shadow(color: Color.gray, radius: 3)
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
                                        }
                                    }
                                }
                                .padding(10)
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
                    })
                })
            }
            .navigationTitle("Account")
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
