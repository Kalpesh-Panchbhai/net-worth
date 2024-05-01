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
                            
                            if(accountViewModel.accountTransactionList.count > 1 && !accountViewModel.account.loanType.elementsEqual("Consumer") && !accountViewModel.account.accountType.elementsEqual(ConstantUtils.brokerAccountType)) {
                                Button(role: .destructive, action: {
                                    if(i==0) {
                                        let updatedDate = Date.now
                                        var account = accountViewModel.account
                                        var accountTransaction = accountViewModel.accountTransactionList[i]
                                        accountTransaction.createdDate = updatedDate
                                        accountTransaction.deleted = true
                                        let newCurrentBalance = accountViewModel.accountTransactionList[1].currentBalance
                                        Task.init {
                                            await accountTransactionController.updateAccountTransaction(accountID: account.id!, accountTransaction: accountTransaction)
                                            account.currentBalance = newCurrentBalance
                                            account.lastUpdated = updatedDate
                                            await accountController.updateAccount(account: account)
                                            await ApplicationData.loadData()
                                            await accountViewModel.getAccountList()
                                            accountViewModel.getAccountTransactionList(id: account.id!)
                                            await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                                            await accountViewModel.getAccount(id: account.id!)
                                        }
                                    } else if(i == accountViewModel.accountTransactionList.count - 1) {
                                        let updatedDate = Date.now
                                        var account = accountViewModel.account
                                        var accountTransaction = accountViewModel.accountTransactionList[i]
                                        accountTransaction.createdDate = updatedDate
                                        accountTransaction.deleted = true
                                        var currentLastTransaction = accountViewModel.accountTransactionList[i - 1]
                                        currentLastTransaction.balanceChange = currentLastTransaction.currentBalance
                                        currentLastTransaction.createdDate = updatedDate
                                        Task.init {
                                            await accountTransactionController.updateAccountTransaction(accountID: account.id!, accountTransaction: accountTransaction)
                                            await accountTransactionController.updateAccountTransaction(accountID: account.id!, accountTransaction: currentLastTransaction)
                                            account.lastUpdated = updatedDate
                                            await accountController.updateAccount(account: account)
                                            await ApplicationData.loadData()
                                            await accountViewModel.getAccountList()
                                            accountViewModel.getAccountTransactionList(id: account.id!)
                                            await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
                                            await accountViewModel.getAccount(id: account.id!)
                                        }
                                    } else {
                                        let updatedDate = Date.now
                                        var account = accountViewModel.account
                                        var accountTransaction = accountViewModel.accountTransactionList[i]
                                        accountTransaction.createdDate = updatedDate
                                        accountTransaction.deleted = true
                                        var currentLastTransaction = accountViewModel.accountTransactionList[i - 1]
                                        let currentFirstTransaction = accountViewModel.accountTransactionList[i + 1]
                                        currentLastTransaction.balanceChange = currentLastTransaction.currentBalance - currentFirstTransaction.currentBalance
                                        currentLastTransaction.createdDate = updatedDate
                                        Task.init {
                                            await accountTransactionController.updateAccountTransaction(accountID: account.id!, accountTransaction: accountTransaction)
                                            await accountTransactionController.updateAccountTransaction(accountID: account.id!, accountTransaction: currentLastTransaction)
                                            account.lastUpdated = updatedDate
                                            await accountController.updateAccount(account: account)
                                            await ApplicationData.loadData()
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
                            } else if(accountViewModel.account.accountType.elementsEqual(ConstantUtils.brokerAccountType) && i == 0) {
                                Button(role: .destructive, action: {
                                    Task.init {
                                        await AccountInBrokerController().deleteTransactionInAccountInBroker(brokerID: accountViewModel.account.id!, accountID: accountViewModel.accountBroker.id!)
                                        await ApplicationData.loadData()
                                        await accountViewModel.getBrokerAccount(brokerID: accountViewModel.account.id!, accountID: accountViewModel.accountBroker.id!)
                                        await accountViewModel.getCurrentBalanceOfAnAccountInBroker(accountBroker: accountViewModel.accountBroker)
                                        await accountViewModel.getAccountTransactionsInBrokerAccountList(brokerID: accountViewModel.account.id!, accountID: accountViewModel.accountBroker.id!)
                                    }
                                }, label: {
                                    Label("Delete", systemImage: ConstantUtils.deleteImageName)
                                })
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
