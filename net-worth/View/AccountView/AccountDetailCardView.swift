//
//  AccountDetailCardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailCardView: View {
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    init(accountViewModel: AccountViewModel) {
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
                Text("\(accountViewModel.account.currentBalance.withCommas(decimalPlace: 2))")
                    .foregroundColor(.white)
                    .font(.caption.bold())
            }
            HStack {
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
        .padding(.horizontal)
        .frame(width: 360,height: 200)
        .padding(8)
        .background(Color(.black))
    }
    
    func getTotalChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? (accountViewModel.accountLastTwoTransactionList[0].balanceChange - accountViewModel.accountLastTwoTransactionList[1].balanceChange) : 0.0
    }
    
    func getOneDayPercentageChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? ((getTotalChangeForNonSymbol() * 100 ) / accountViewModel.accountLastTwoTransactionList[1].balanceChange) : 0.0
    }
}
