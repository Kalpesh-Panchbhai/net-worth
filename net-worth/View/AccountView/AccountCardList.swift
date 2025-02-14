//
//  CardList.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct AccountCardList: View {
    
    var accountController = AccountController()
    
    @State var hideZeroAmountAccount = true
    @State var isNewAccountAccountViewOpen = false
    @State var searchText = ""
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
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
                                BalanceCardView(accountType: "Net Worth", isWatchListCardView: false, watchList: WatchRestModel())
                                    .frame(width: 360, height: 70)
                                    .cornerRadius(10)
                                NetworthCardView()
                                    .frame(width: 360, height: 30)
                                    .cornerRadius(10)
                            }
                            Divider()
                                .overlay(Color.theme.secondaryText)
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack {
                                    ForEach(accountViewModel.sectionHeaders, id: \.self) { accountType in
                                        if(showAccountType(accountType: accountType)) {
                                            if(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 0) {
                                                HStack {
                                                    Text(accountType)
                                                        .foregroundColor(Color.theme.primaryText)
                                                        .bold()
                                                        .font(.system(size: 15))
                                                    Spacer()
                                                    NavigationLink(destination: {
                                                        AccountListView(accountType: accountType)
                                                            .toolbarRole(.editor)
                                                    }, label: {
                                                        Text("See all")
                                                            .foregroundColor(Color.theme.secondaryText)
                                                            .font(.system(size: 12))
                                                    })
                                                }
                                                .padding(.horizontal, 8)
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack {
                                                        ForEach(0..<((accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 5) ? 5 : accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count), id: \.self) { i in
                                                            if(showAccount(account: (accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i]))) {
                                                                NavigationLink(destination: {
                                                                    AccountDetailView(accountID: (accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i]).id)
                                                                        .toolbarRole(.editor)
                                                                }) {
                                                                    AccountCardView(account: (accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i]))
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
                ToolbarItem(placement: .navigationBarLeading, content: {
                    Menu(content: {
                        Toggle(isOn: $hideZeroAmountAccount, label: {
                            Text("Hide zero amount accounts")
                        })
                        
                    }, label: {
                        ZStack {
                            Circle()
                                .frame(width: 25, height: 25)
                                .foregroundColor(ColorTheme().foreground)
                            Image(systemName: ConstantUtils.menuImageName)
                                .foregroundColor(Color.theme.primaryText)
                                .font(.system(size: 12))
                        }
                    })
                    .font(.system(size: 14).bold())
                })
                
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button(action: {
                        isNewAccountAccountViewOpen.toggle()
                    }, label: {
                        ZStack {
                            Circle()
                                .frame(width: 25, height: 25)
                                .foregroundColor(ColorTheme().green)
                            Image(systemName: ConstantUtils.plusImageName)
                                .foregroundColor(Color.theme.background)
                                .font(.system(size: 12))
                        }
                    })
                    .font(.system(size: 14))
                })
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isNewAccountAccountViewOpen, onDismiss: {
        }, content: {
            NewAccountView(accountType: ConstantUtils.noneAccountType)
        })
    }
    
    private func isAccountAmountZero(account: AccountRestModel) -> Bool {
        return account.value.currentValue.isZero
    }
    
    private func showAccount(account: AccountRestModel) -> Bool {
        return true
//        return ((hideZeroAmountAccount && !isAccountAmountZero(account: account)) || !hideZeroAmountAccount)
    }
    
    private func areAllAccountsForAccountTypeZero(accountType: String) -> Bool {
        let accountList = accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)
        var isZero = true
        for account in accountList {
            if(!isAccountAmountZero(account: account)) {
                isZero = false
                break
            }
        }
        return isZero
    }
    
    private func showAccountType(accountType: String) -> Bool {
        return true
//        return ((hideZeroAmountAccount && !areAllAccountsForAccountTypeZero(accountType: accountType)) || !hideZeroAmountAccount)
    }
}
