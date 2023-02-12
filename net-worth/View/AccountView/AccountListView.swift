//
//  AccountListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountListView: View {
    
    var accountType: String
    
    @StateObject var accountViewModel = AccountViewModel()
    
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)), Color(#colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1))]),
                           center: .topLeading,
                           startRadius: 5,
                           endRadius: UIScreen.main.bounds.height)
            .ignoresSafeArea()
            ScrollView(.vertical) {
                LazyVStack {
                    ForEach(accountViewModel.sectionContent(key: accountType, searchKeyword: ""), id: \.self) { account in
                        NavigationLink(destination: {
                            AccountDetailView(account: account, accountViewModel: accountViewModel)
                        }, label: {
                            AccountRowView(account: account)
                                .shadow(color: Color.black, radius: 3)
                            Divider()
                        })
                    }
                }
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
            }
        }
        .background(Color.gray)
    }
}

