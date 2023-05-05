//
//  TransactionView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct TransactionsView: View {
    
    @ObservedObject private var accountViewModel: AccountViewModel
    
    @State private var index = 0
    
    private var accountTransactionList = [AccountTransaction]()
    
    private var accountController = AccountController()
    
    init(accountViewModel: AccountViewModel) {
        self.accountViewModel = accountViewModel
        self.accountTransactionList = accountViewModel.accountTransactionList
    }
    
    var body: some View {
        VStack {
            ScrollView(.vertical) {
                LazyVStack {
                    ForEach(0..<accountViewModel.accountTransactionList.count, id: \.self) { i in
                        HStack{
                            VStack(alignment: .leading) {
                                Text("\(accountViewModel.accountTransactionList[i].timestamp.getDateAndFormat())")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("\(accountViewModel.accountTransactionList[i].timestamp.getTimeAndFormat())")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text((accountViewModel.account.currency) + " \(accountViewModel.accountTransactionList[i].currentBalance.withCommas(decimalPlace: 4))")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                if( i < accountViewModel.accountTransactionList.count) {
                                    if(accountViewModel.accountTransactionList[i].balanceChange > 0) {
                                        Text("+\(accountViewModel.accountTransactionList[i].balanceChange.withCommas(decimalPlace: 2))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.green)
                                    } else if(accountViewModel.accountTransactionList[i].balanceChange < 0) {
                                        Text("\(accountViewModel.accountTransactionList[i].balanceChange.withCommas(decimalPlace: 2))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .contextMenu {
                            Label(accountViewModel.accountTransactionList[i].id!, systemImage: "info.square")
                            
                            if(i == 0 && accountViewModel.accountTransactionList.count > 1) {
                                Button(role: .destructive, action: {
                                    var account = accountViewModel.account
                                    let accountTransactionID = accountViewModel.accountTransactionList[i].id!
                                    let newCurrentBalance = accountViewModel.accountTransactionList[1].balanceChange
                                    Task.init {
                                        try await accountController.deleteAccountLastTransaction(accountID: account.id!, accountTransactionID: accountTransactionID)
                                        account.currentBalance = newCurrentBalance
                                        accountController.updateAccount(account: account)
                                        await accountViewModel.getAccountTransactionList(id: account.id!)
                                        await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                                        await accountViewModel.getAccount(id: account.id!)
                                    }
                                }, label: {
                                    Label("Delete", systemImage: "trash")
                                })
                            }
                        }
                        .padding(.horizontal)
                        .padding(8)
                    }
                }
            }
            .background(Color.black)
            .cornerRadius(10)
        }
        .background(Color.black)
    }
}
