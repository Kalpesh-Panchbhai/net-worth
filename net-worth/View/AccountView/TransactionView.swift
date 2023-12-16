//
//  TransactionView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct TransactionsView: View {
    
    var accountTransactionList = [AccountTransaction]()
    var accountController = AccountController()
    var accountTransactionController = AccountTransactionController()
    
    @State var index = 0
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    init(accountViewModel: AccountViewModel) {
        self.accountViewModel = accountViewModel
        self.accountTransactionList = accountViewModel.accountTransactionList
    }
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    Spacer()
                    ForEach(0..<accountViewModel.accountTransactionList.count, id: \.self) { i in
                        HStack{
                            VStack(alignment: .leading) {
                                Text("\(accountViewModel.accountTransactionList[i].timestamp.getDateAndFormat())")
                                    .font(.headline)
                                    .foregroundColor(Color.theme.primaryText)
                                    .padding(.horizontal)
                                HStack {
                                    Text("\(accountViewModel.accountTransactionList[i].timestamp.getTimeAndFormat())")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.theme.secondaryText)
                                        .padding(.leading)
                                    if(accountViewModel.account.loanType.elementsEqual("Consumer")) {
                                        if(accountViewModel.accountTransactionList[i].paid) {
                                            Text("Paid")
                                                .font(.system(size: 12).bold())
                                                .foregroundColor(Color.theme.green)
                                        } else {
                                            Text("Not Paid")
                                                .font(.system(size: 12).bold())
                                                .foregroundColor(Color.theme.red)
                                        }
                                    }
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                HStack {
                                    Text(accountViewModel.account.currency)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.theme.secondaryText)
                                    Text(accountViewModel.accountTransactionList[i].currentBalance.withCommas(decimalPlace: 4))
                                        .font(.headline)
                                        .foregroundColor(Color.theme.primaryText)
                                }
                                .padding(.horizontal)
                                if( i < accountViewModel.accountTransactionList.count) {
                                    if(accountViewModel.accountTransactionList[i].balanceChange > 0) {
                                        HStack {
                                            Text("+\(accountViewModel.accountTransactionList[i].balanceChange.withCommas(decimalPlace: 4))")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.theme.green)
                                            if(i < accountViewModel.accountTransactionList.count - 1) {
                                                Text("(+" + calculatePercentChange(amount1: accountViewModel.accountTransactionList[i].currentBalance, amount2: accountViewModel.accountTransactionList[i + 1].currentBalance) + ")")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.theme.green)
                                            }
                                        }
                                        .padding(.horizontal)
                                    } else if(accountViewModel.accountTransactionList[i].balanceChange < 0) {
                                        HStack {
                                            Text("\(accountViewModel.accountTransactionList[i].balanceChange.withCommas(decimalPlace: 4))")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color.theme.red)
                                            if(i < accountViewModel.accountTransactionList.count - 1) {
                                                Text("(" + calculatePercentChange(amount1: accountViewModel.accountTransactionList[i].currentBalance, amount2: accountViewModel.accountTransactionList[i + 1].currentBalance) + ")")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.theme.red)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .frame(width: 360)
                        .contextMenu {
                            Label(accountViewModel.accountTransactionList[i].id!, systemImage: ConstantUtils.infoIconImageName)
                            
                            if(accountViewModel.accountTransactionList.count > 1 && !accountViewModel.account.loanType.elementsEqual("Consumer")) {
                                Button(role: .destructive, action: {
                                    if(i==0) {
                                        var account = accountViewModel.account
                                        let accountTransactionID = accountViewModel.accountTransactionList[i].id!
                                        let newCurrentBalance = accountViewModel.accountTransactionList[1].currentBalance
                                        Task.init {
                                            await accountTransactionController.deleteAccountTransaction(accountID: account.id!, id: accountTransactionID)
                                            account.currentBalance = newCurrentBalance
                                            account.lastUpdated = Date.now
                                            await accountController.updateAccount(account: account)
                                            await accountViewModel.getAccountList()
                                            accountViewModel.getAccountTransactionList(id: account.id!)
                                            await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                                            await accountViewModel.getAccount(id: account.id!)
                                        }
                                    } else if(i == accountViewModel.accountTransactionList.count - 1) {
                                        let account = accountViewModel.account
                                        let accountTransactionID = accountViewModel.accountTransactionList[i].id!
                                        var currentLastTransaction = accountViewModel.accountTransactionList[i - 1]
                                        currentLastTransaction.balanceChange = currentLastTransaction.currentBalance
                                        Task.init {
                                            await accountTransactionController.deleteAccountTransaction(accountID: account.id!, id: accountTransactionID)
                                            await accountTransactionController.updateAccountTransaction(accountID: account.id!, accountTransaction: currentLastTransaction)
                                            await accountViewModel.getAccountList()
                                            accountViewModel.getAccountTransactionList(id: account.id!)
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
                                            await accountTransactionController.deleteAccountTransaction(accountID: account.id!, id: accountTransactionID)
                                            await accountTransactionController.updateAccountTransaction(accountID: account.id!, accountTransaction: currentLastTransaction)
                                            await accountViewModel.getAccountList()
                                            accountViewModel.getAccountTransactionList(id: account.id!)
                                            await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                                            await accountViewModel.getAccount(id: account.id!)
                                        }
                                    }
                                }, label: {
                                    Label("Delete", systemImage: ConstantUtils.deleteImageName)
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
                                            await accountTransactionController.updateAccountTransaction(accountID: account.id!, accountTransaction: accountTransaction)
                                            await accountController.updateAccount(account: account)
                                            accountViewModel.getAccountTransactionList(id: account.id!)
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
                        .background(Color.theme.foreground)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(8)
            .background(Color.theme.background)
        }
    }
    
    private func calculatePercentChange(amount1: Double, amount2: Double) -> String {
        return CommonController.getGrowthPercentage(previousBalance: amount2, currentBalance: amount1)
    }
}
