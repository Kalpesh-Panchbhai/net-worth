//
//  CardList.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct CardList: View {
    
    @State private var isOpen: Bool = false
    @State private var selectedAccount = Account()
    
    @StateObject var accountViewModel = AccountViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)), Color(#colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1))]),
                               center: .topLeading,
                               startRadius: 5,
                               endRadius: UIScreen.main.bounds.height)
                .ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(accountViewModel.sectionHeaders, id: \.self) { accountType in
                            HStack {
                                Text(accountType.uppercased())
                                    .bold()
                                    .foregroundColor(.white)
                                Spacer()
                                if(accountViewModel.sectionContent(key: accountType, searchKeyword: "").count > 5) {
                                    Button(action: {
                                        
                                    }, label: {
                                        Label("See more", systemImage: "")
                                    }).foregroundColor(.green)
                                }
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack {
                                    ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: ""), id: \.self) { account in
                                        NavigationLink(destination: AccountDetailView(account: account)) {
                                            CardView(account: account)
                                                .shadow(color: Color.black, radius: 3)
                                        }
                                    }
                                    .padding(2)
                                }
                            }
                        }
                    }
                    .padding(10)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        
                    }) {
                        Text("+")
                    }
                }
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance()
            }
        }
    }
}
