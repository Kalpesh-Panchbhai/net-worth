//
//  AccountRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountRowView: View {
    
    private var account: Account
    
    @StateObject var financeListViewModel = FinanceListViewModel()
    @ObservedObject var accountViewModel: AccountViewModel
    
    init(account: Account, accountViewModel: AccountViewModel) {
        self.account = account
        self.accountViewModel = accountViewModel
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(account.accountName)
                    .foregroundColor(.white)
                    .font(.caption.bold())
                Spacer()
                if(account.paymentReminder) {
                    Label("", systemImage: "bell.fill")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                } else {
                    Label("", systemImage: "bell.slash.fill")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                }
            }
            Spacer()
            HStack {
                if(!account.symbol.isEmpty) {
                    Text("\(account.totalShares.withCommas(decimalPlace: 2)) Units")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                }
                Spacer()
                Text(account.currency)
                    .foregroundColor(.white)
                    .font(.caption)
                if(!account.symbol.isEmpty) {
                    Text("\(getCurrentBalanceForSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                } else {
                    Text("\(account.currentBalance.withCommas(decimalPlace: 2))")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                }
            }
            Spacer()
            HStack {
                if(account.paymentReminder) {
                    Text("\(account.paymentDate)")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                }
                Spacer()
                if(!account.symbol.isEmpty) {
                    if(getTotalChangeForSymbol() >= 0) {
                        Text("\(getTotalChangeForSymbol().withCommas(decimalPlace: 2))")
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding(.bottom)
                        Text("(\(getOneDayPercentageChangeForSymbol().withCommas(decimalPlace: 2))%)")
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding(.bottom)
                    } else {
                        Text("\(getTotalChangeForSymbol().withCommas(decimalPlace: 2))")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.bottom)
                        Text("(\(getOneDayPercentageChangeForSymbol().withCommas(decimalPlace: 2))%)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.bottom)
                    }
                } else {
                    if(getTotalChangeForNonSymbol() >= 0) {
                        Text("\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding(.bottom)
                        Text("(\(getOneDayPercentageChangeForNonSymbol().withCommas(decimalPlace: 2))%)")
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding(.bottom)
                    } else {
                        Text("\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.bottom)
                        Text("(\(getOneDayPercentageChangeForNonSymbol().withCommas(decimalPlace: 2))%)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.bottom)
                    }
                }
            }
        }
        .onAppear {
            print(account.accountName)
            Task.init {
                await financeListViewModel.getSymbolDetails(symbol: account.symbol)
                await accountViewModel.getLastTwoAccountTransactionList(id: account.id ?? "")
            }
        }
        .padding(.horizontal)
        .background(Color(.black))
        .cornerRadius(20)
    }
    
    func getTotalChangeForSymbol() -> Double {
        return (financeListViewModel.financeDetailModel.oneDayChange ?? 0.0) * account.totalShares
    }
    
    func getCurrentBalanceForSymbol() -> Double {
        return (financeListViewModel.financeDetailModel.regularMarketPrice ?? 0.0) * account.totalShares
    }
    
    func getOneDayPercentageChangeForSymbol() -> Double {
        return financeListViewModel.financeDetailModel.oneDayPercentChange ?? 0.0
    }
    
    func getTotalChangeForNonSymbol() -> Double {
        return accountViewModel.accountTransactionList.count > 1 ? (accountViewModel.accountTransactionList[0].balanceChange - accountViewModel.accountTransactionList[1].balanceChange) : 0.0
    }
    
    func getOneDayPercentageChangeForNonSymbol() -> Double {
        return accountViewModel.accountTransactionList.count > 1 ? ((getTotalChangeForNonSymbol() * 100 ) / accountViewModel.accountTransactionList[1].balanceChange) : 0.0
    }
}
