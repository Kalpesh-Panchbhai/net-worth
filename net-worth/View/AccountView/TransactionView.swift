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
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                HStack {
                                    Text("\(accountViewModel.accountTransactionList[i].timestamp.getTimeAndFormat())")
                                        .font(.system(size: 12))
                                        .foregroundColor(.black)
                                        .padding(.horizontal)
                                    if(accountViewModel.account.loanType.elementsEqual("Consumer")) {
                                        if(accountViewModel.accountTransactionList[i].paid) {
                                            Text("Paid")
                                                .font(.system(size: 12))
                                                .foregroundColor(.green)
                                        } else {
                                            Text("Not Paid")
                                                .font(.system(size: 12))
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text((accountViewModel.account.currency) + " \(accountViewModel.accountTransactionList[i].currentBalance.withCommas(decimalPlace: 4))")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                if( i < accountViewModel.accountTransactionList.count) {
                                    if(accountViewModel.accountTransactionList[i].balanceChange > 0) {
                                        Text("+\(accountViewModel.accountTransactionList[i].balanceChange.withCommas(decimalPlace: 2))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.green)
                                            .padding(.horizontal)
                                    } else if(accountViewModel.accountTransactionList[i].balanceChange < 0) {
                                        Text("\(accountViewModel.accountTransactionList[i].balanceChange.withCommas(decimalPlace: 2))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .contextMenu {
                            Label(accountViewModel.accountTransactionList[i].id!, systemImage: "info.square")
                            
                            if(accountViewModel.accountTransactionList.count > 1 && !accountViewModel.account.loanType.elementsEqual("Consumer")) {
                                Button(role: .destructive, action: {
                                    if(i==0) {
                                        var account = accountViewModel.account
                                        let accountTransactionID = accountViewModel.accountTransactionList[i].id!
                                        let newCurrentBalance = accountViewModel.accountTransactionList[1].currentBalance
                                        Task.init {
                                            try await accountController.deleteAccountTransaction(accountID: account.id!, accountTransactionID: accountTransactionID)
                                            account.currentBalance = newCurrentBalance
                                            accountController.updateAccount(account: account)
                                            await accountViewModel.getAccountTransactionList(id: account.id!)
                                            await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                                            await accountViewModel.getAccount(id: account.id!)
                                        }
                                    } else if(i == accountViewModel.accountTransactionList.count - 1) {
                                        let account = accountViewModel.account
                                        let accountTransactionID = accountViewModel.accountTransactionList[i].id!
                                        var currentLastTransaction = accountViewModel.accountTransactionList[i - 1]
                                        currentLastTransaction.balanceChange = currentLastTransaction.currentBalance
                                        Task.init {
                                            try await accountController.deleteAccountTransaction(accountID: account.id!, accountTransactionID: accountTransactionID)
                                            accountController.updateAccountTransaction(accountTransaction: currentLastTransaction, accountID: account.id!)
                                            await accountViewModel.getAccountTransactionList(id: account.id!)
                                            await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                                            await accountViewModel.getAccount(id: account.id!)
                                        }
                                    } else {
                                        let account = accountViewModel.account
                                        let accountTransactionID = accountViewModel.accountTransactionList[i].id!
                                        var currentLastTransaction = accountViewModel.accountTransactionList[i - 1]
                                        let currentFirstTransaction = accountViewModel.accountTransactionList[i + 1]
                                        currentLastTransaction.balanceChange = currentLastTransaction.currentBalance - currentFirstTransaction.currentBalance
                                        Task.init {
                                            try await accountController.deleteAccountTransaction(accountID: account.id!, accountTransactionID: accountTransactionID)
                                            accountController.updateAccountTransaction(accountTransaction: currentLastTransaction, accountID: account.id!)
                                            await accountViewModel.getAccountTransactionList(id: account.id!)
                                            await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                                            await accountViewModel.getAccount(id: account.id!)
                                        }
                                    }
                                }, label: {
                                    Label("Delete", systemImage: "trash")
                                })
                            } else if(accountViewModel.account.loanType.elementsEqual("Consumer")) {
                                if((i == (accountViewModel.accountTransactionList.count - accountViewModel.accountTransactionList.filter { item in
                                    item.paid
                                }.count) - 1) && accountViewModel.accountTransactionList[i].timestamp<=Date.now) {
                                    Button(action: {
                                        var account = accountViewModel.account
                                        var accountTransaction = accountViewModel.accountTransactionList[i]
                                        accountTransaction.paid = true
                                        account.currentBalance = accountTransaction.currentBalance
                                        Task.init {
                                            accountController.updateAccountTransaction(accountTransaction: accountTransaction, accountID: account.id!)
                                            accountController.updateAccount(account: account)
                                            await accountViewModel.getAccountTransactionList(id: account.id!)
                                            await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                                            await accountViewModel.getAccount(id:account.id!)
                                        }
                                    }, label: {
                                        Label("Pay", systemImage: "indianrupeesign")
                                    })
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(#colorLiteral(red: 0.9058823529, green: 0.9490196078, blue: 0.9803921569, alpha: 1)))
                        .cornerRadius(10)
                        .shadow(color: Color(#colorLiteral(red: 0.06666666667, green: 0.1529411765, blue: 0.4352941176, alpha: 1)), radius: 3)
                    }
                }
            }
            .padding(8)
            .background(Color(#colorLiteral(red: 0.06666666667, green: 0.1529411765, blue: 0.4352941176, alpha: 1)))
        }
    }
}
