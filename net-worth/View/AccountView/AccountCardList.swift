//
//  CardList.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct AccountCardList: View {
    
    @State private var isNewAccountTypeAcountViewOpen = false
    @State private var isNewTransactionViewOpen = false
    @State private var accountTypeSelected = "None"
    @State private var selectedAccount = Account()
    @State private var searchText = ""
    @State private var longPressedItem = 0
    @State private var longPressedAccountType = ""
    
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var financeListViewModel = FinanceListViewModel()
    
    private var accountController = AccountController()
    
    var body: some View {
        NavigationView {
            ZStack {
                RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)), Color(#colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1))]),
                               center: .topLeading,
                               startRadius: 5,
                               endRadius: UIScreen.main.bounds.height)
                .ignoresSafeArea()
                VStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        TotalAccountBalanceCardView(accountViewModel: accountViewModel)
                            .shadow(color: Color.black, radius: 3)
                            .cornerRadius(10)
                        LazyVStack {
                            ForEach(accountViewModel.sectionHeaders, id: \.self) { accountType in
                                HStack {
                                    Text(accountType.uppercased())
                                        .bold()
                                        .foregroundColor(.white)
                                        .font(.system(size: 15))
                                    Spacer()
                                    if(accountViewModel.sectionContent(key: accountType, searchKeyword: "").count > 5) {
                                        NavigationLink(destination: {
                                            AccountListView(accountType: accountType)
                                        }, label: {
                                            Label("See more", systemImage: "")
                                                .foregroundColor(.green)
                                                .bold()
                                                .font(.system(size: 15))
                                        })
                                    }
                                }
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack {
                                        VStack(spacing: 50) {
                                            NewAccountCardView()
                                                .onTapGesture(perform: {
                                                    if(accountType == "Credit Card" || accountType == "Saving" || accountType == "Loan" || accountType == "Other") {
                                                        self.accountTypeSelected = accountType
                                                    } else {
                                                        self.accountTypeSelected = "Symbol"
                                                    }
                                                    isNewAccountTypeAcountViewOpen.toggle()
                                                })
                                            Spacer()
                                        }
                                        ForEach(0..<((accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count > 5) ? 5 : accountViewModel.sectionContent(key: accountType, searchKeyword: searchText).count), id: \.self) { i in
                                            VStack {
                                                NavigationLink(destination: AccountDetailView(account: accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i],accountViewModel:  accountViewModel)) {
                                                    AccountCardView(account: accountViewModel.sectionContent(key: accountType, searchKeyword: searchText)[i])
                                                        .shadow(color: Color.black, radius: 3)
                                                        .contextMenu {
                                                            Button(role: .destructive, action: {
                                                                accountController.deleteAccount(account: accountViewModel.sectionContent(key: accountType, searchKeyword: "")[i])
                                                                Task.init {
                                                                    await accountViewModel.getAccountList()
                                                                    await accountViewModel.getTotalBalance()
                                                                }
                                                            }, label: {
                                                                Label("Delete", systemImage: "trash")
                                                            })
                                                            
                                                            Button {
                                                                print("New Transaction")
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
                                        .padding(10)
                                        
                                    }
                                    .padding(5)
                                }
                            }
                        }
                        .padding(10)
                        WatchListView()
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AccountCardListExpendableButton(accountViewModel: accountViewModel)
                    }.padding([.bottom,.trailing],30)
                }
            }
        }
        .halfSheet(showSheet: $isNewTransactionViewOpen) {
            UpdateBalanceAccountView(accountViewModel: accountViewModel, financeListViewModel: financeListViewModel)
        }
        .halfSheet(showSheet: $isNewAccountTypeAcountViewOpen) {
            NewAccountView(accountType: accountTypeSelected, accountViewModel: accountViewModel)
        }
        .searchable(text: $searchText)
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance()
            }
        }
    }
}
