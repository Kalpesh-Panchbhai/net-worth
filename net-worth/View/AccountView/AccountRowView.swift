//
//  AccountRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountRowView: View {
    
    private var account: Account
    
    @StateObject var accountViewModel = AccountViewModel()
    
    init(account: Account) {
        self.account = account
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(accountViewModel.account.accountName)
                    .foregroundColor(.black)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Spacer()
                if(accountViewModel.account.paymentReminder && accountViewModel.account.accountType != "Saving") {
                    Label("", systemImage: "bell.fill")
                        .foregroundColor(.black)
                        .font(.caption.bold())
                    Text("\(accountViewModel.account.paymentDate)")
                        .foregroundColor(.black)
                        .font(.caption.bold())
                } else if(accountViewModel.account.accountType != "Saving") {
                    Label("", systemImage: "bell.slash.fill")
                        .foregroundColor(.black)
                        .font(.caption.bold())
                }
            }
            Spacer()
            HStack {
                Text(accountViewModel.account.currency)
                    .foregroundColor(.black)
                    .font(.caption.bold())
                Text("\(accountViewModel.account.currentBalance.withCommas(decimalPlace: 2))")
                    .foregroundColor(.black)
                    .font(.caption.bold())
            }
            Spacer()
            HStack {
                if(getTotalChangeForNonSymbol() >= 0) {
                    Text("\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(.green)
                        .font(.caption.bold())
                        .padding(.bottom)
                    Text("(\(getOneDayPercentageChangeForNonSymbol().withCommas(decimalPlace: 2))%)")
                        .foregroundColor(.green)
                        .font(.caption.bold())
                        .padding(.bottom)
                } else {
                    Text("\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(.red)
                        .font(.caption.bold())
                        .padding(.bottom)
                    Text("(\(getOneDayPercentageChangeForNonSymbol().withCommas(decimalPlace: 2))%)")
                        .foregroundColor(.red)
                        .font(.caption.bold())
                        .padding(.bottom)
                }
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccount(id: account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: account.id!)
            }
        }
        .padding(.horizontal)
        .background(Color(#colorLiteral(red: 0.9058823529, green: 0.9490196078, blue: 0.9803921569, alpha: 1)))
        .cornerRadius(10)
    }
    
    func getTotalChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? (accountViewModel.accountLastTwoTransactionList[0].balanceChange) : 0.0
    }
    
    func getOneDayPercentageChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? ((getTotalChangeForNonSymbol() * 100 ) / accountViewModel.accountLastTwoTransactionList[1].currentBalance) : 0.0
    }
}
