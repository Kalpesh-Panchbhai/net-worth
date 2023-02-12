//
//  CardList.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct AccountCardList: View {
    
    @State private var isNewAccountTypeAcountViewOpen = false
    @State private var accountTypeSelected = "None"
    @State private var show = false
    @State private var selectedAccount = Account()
    @State private var searchText = ""
    
    @StateObject var accountViewModel = AccountViewModel()
    
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
                                        VStack(spacing: 100) {
                                            NewAccountCardView()
                                                .onTapGesture(perform: {
                                                    if(accountType == "Credit Card" || accountType == "Saving" || accountType == "Loan" || accountType == "Other") {
                                                        self.accountTypeSelected = accountType
                                                    } else {
                                                        self.accountTypeSelected = "Symbol"
                                                    }
                                                    print(accountTypeSelected)
                                                    isNewAccountTypeAcountViewOpen.toggle()
                                                })
                                            Spacer()
                                        }
                                        ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: searchText), id: \.self) { account in
                                            VStack {
                                                NavigationLink(destination: AccountDetailView(account: account,accountViewModel:  accountViewModel)) {
                                                    AccountCardView(account: account)
                                                        .shadow(color: Color.black, radius: 3)
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
        .halfSheet(showSheet: $isNewAccountTypeAcountViewOpen) {
            NewAccountView(accountType: accountTypeSelected, accountViewModel: accountViewModel)
//            NewAccountView(accountViewModel: accountViewModel, accountType: <#T##String#>)
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
