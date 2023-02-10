//
//  AccountDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailView: View {
    
    private var account: Account
    
    @State private var show = false
    
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var financeListViewModel = FinanceListViewModel()
    
    @Environment(\.presentationMode) var presentationMode
    
    init(account: Account) {
        self.account = account
    }
    
    var body: some View {
        ZStack {
            VStack {
                AccountDetailCardView(financeListViewModel: financeListViewModel, accountViewModel: accountViewModel)
                    .cornerRadius(20)
                    .shadow(color: Color.gray, radius: 3)
                TransactionsView(accountViewModel: accountViewModel)
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AccountDetailExpendableButton(show: $show, accountViewModel: accountViewModel, financeListViewModel: financeListViewModel, presentationMode: _presentationMode, account: account)
                }.padding([.trailing],30)
                    .padding(.bottom,80)
            }
        }
        .onAppear {
            Task.init {
                await financeListViewModel.getSymbolDetails(symbol: account.symbol)
                await accountViewModel.getAccount(id: account.id!)
                await accountViewModel.getAccountTransactionList(id: account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
            }
        }
        .background(.black)
    }
}
