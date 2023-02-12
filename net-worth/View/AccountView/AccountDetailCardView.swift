//
//  AccountDetailCardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailCardView: View {
    
    @ObservedObject var financeListViewModel: FinanceListViewModel
    @ObservedObject var accountViewModel: AccountViewModel
   
    init(financeListViewModel: FinanceListViewModel, accountViewModel: AccountViewModel) {
        self.financeListViewModel = financeListViewModel
        self.accountViewModel = accountViewModel
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(accountViewModel.account.accountName)
                    .foregroundColor(.white)
                    .font(.headline.bold())
                Spacer()
                if(accountViewModel.account.paymentReminder) {
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
                if(!accountViewModel.account.symbol.isEmpty) {
                    Text("\(accountViewModel.account.totalShares.withCommas(decimalPlace: 2)) Units")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                }
            }
            Spacer()
            HStack {
                if(accountViewModel.account.paymentReminder) {
                    Text("\(accountViewModel.account.paymentDate)")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                }
            }
            Spacer()
            HStack(alignment: .center) {
                Text(accountViewModel.account.currency)
                    .foregroundColor(.white)
                    .font(.caption)
                if(!accountViewModel.account.symbol.isEmpty) {
                    Text("\(getCurrentBalanceForSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                } else {
                    Text("\(accountViewModel.account.currentBalance.withCommas(decimalPlace: 2))")
                        .foregroundColor(.white)
                        .font(.caption.bold())
                }
            }
            HStack {
                if(!accountViewModel.account.symbol.isEmpty) {
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
        .padding(.horizontal)
        .frame(width: 360,height: 200)
        .padding(8)
        .background(Color(.black))
    }
    
    func getTotalChangeForSymbol() -> Double {
        return (financeListViewModel.financeDetailModel.oneDayChange ?? 0.0) * accountViewModel.account.totalShares
    }
    
    func getCurrentBalanceForSymbol() -> Double {
        return (financeListViewModel.financeDetailModel.regularMarketPrice ?? 0.0) * accountViewModel.account.totalShares
    }
    
    func getOneDayPercentageChangeForSymbol() -> Double {
        return financeListViewModel.financeDetailModel.oneDayPercentChange ?? 0.0
    }
    
    func getTotalChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? (accountViewModel.accountLastTwoTransactionList[0].balanceChange - accountViewModel.accountLastTwoTransactionList[1].balanceChange) : 0.0
    }
    
    func getOneDayPercentageChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? ((getTotalChangeForNonSymbol() * 100 ) / accountViewModel.accountLastTwoTransactionList[1].balanceChange) : 0.0
    }
}
