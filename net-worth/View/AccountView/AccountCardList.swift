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
    @State var hideInactiveAccount = true
    @State var hideZeroBalanceAccount = true
    
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
                                VStack {
                                    ForEach(accountViewModel.sectionHeaders, id: \.self) { accountType in
                                        if(((accountType.elementsEqual("Inactive Account") && !hideInactiveAccount) || (!accountType.elementsEqual("Inactive Account"))) && ((hideZeroBalanceAccount && isAllAccountsInAAccountTypeAreZero(accountType: accountType, searchText: searchText)) || !hideZeroBalanceAccount)) {
                                            if(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 0) {
                                                HStack {
                                                    Text(accountType)
                                                        .foregroundColor(Color.theme.primaryText)
                                                        .bold()
                                                        .font(.system(size: 15))
                                                    Spacer()
                                                    NavigationLink(destination: {
                                                        AccountListView(accountType: accountType, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
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
                                                            if((hideZeroBalanceAccount && isAccountBalanceIsZero(id: (accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i]).id)) || !hideZeroBalanceAccount) {
                                                                NavigationLink(destination: {
                                                                    AccountDetailView(accountID: (accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i]).id, accountViewModel:  accountViewModel, watchViewModel: watchViewModel)
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
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button(action: {
                        isNewAccountAccountViewOpen.toggle()
                    }, label: {
                        Image(systemName: ConstantUtils.plusImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                })
                ToolbarItem(placement: .navigationBarLeading, content: {
                    Menu(content: {
                        Toggle(isOn: $hideInactiveAccount, label: {
                            Text("Hide Inactive Accounts")
                        })
                        
                        Toggle(isOn: $hideZeroBalanceAccount, label: {
                            Text("Hide Zero Balance Accounts")
                        })
                    }, label: {
                        Image(systemName: ConstantUtils.menuImageName)
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                })
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isNewAccountAccountViewOpen, onDismiss: {
        }, content: {
            NewAccountView(accountType: ConstantUtils.noneAccountType, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
        })
    }
    
    private func isAccountActive(id: String) -> Bool {
        return ApplicationData.shared.data.accountDataList.filter {
            $0.account.id.elementsEqual(id) && $0.account.active
        }.count > 0
    }
    
    private func isAccountBalanceIsZero(id: String) -> Bool {
        let accountList = ApplicationData.shared.chartDataList
        return accountList.first(where: {
            return $0.key.elementsEqual(id)
        })?.value.last?.value != 0
    }
    
    private func isAllAccountsInAAccountTypeAreZero(accountType: String, searchText: String) -> Bool {
        let accountList = accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)
        var isAllAccountsInAAccountTypeAreZero = true
        for account in accountList {
            if(!isAccountBalanceIsZero(id: account.id)) {
                isAllAccountsInAAccountTypeAreZero = false
                break
            }
        }
        return isAllAccountsInAAccountTypeAreZero
    }
}
