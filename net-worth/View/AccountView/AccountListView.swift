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
    @StateObject var financeListViewModel = FinanceListViewModel()
    
    var accountController = AccountController()
    
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)), Color(#colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1))]),
                           center: .topLeading,
                           startRadius: 5,
                           endRadius: UIScreen.main.bounds.height)
            .ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                BalanceCardView(accountViewModel: accountViewModel, accountType: accountType)
                    .shadow(color: Color.black, radius: 3)
                    .cornerRadius(10)
                LazyVStack {
                    ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                        NavigationLink(destination: {
                            AccountDetailView(account: account, accountViewModel: accountViewModel)
                        }, label: {
                            AccountRowView(account: account)
                                .shadow(color: Color.black, radius: 3)
                                .contextMenu {
                                    Button(role: .destructive, action: {
                                        accountController.deleteAccount(account: account)
                                        Task.init {
                                            await accountViewModel.getAccountList()
                                            await accountViewModel.getTotalBalance(accountList: accountViewModel.sectionContent(key: accountType, searchKeyword: ""))
                                        }
                                    }, label: {
                                        Label("Delete", systemImage: "trash")
                                    })
                                    
                                    Button {
                                        print("New Transaction")
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
                await financeListViewModel.getSymbolDetails(symbol: accountViewModel.account.symbol)
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance(accountList: accountViewModel.sectionContent(key: accountType, searchKeyword: ""))
            }
        }, content: {
            UpdateBalanceAccountView(accountViewModel: accountViewModel, financeListViewModel: financeListViewModel)
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

