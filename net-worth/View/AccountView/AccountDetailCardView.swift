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
            HStack {
                Text(accountViewModel.account.currency)
                    .foregroundColor(Color.navyBlue)
                    .font(.caption.bold())
                Text("\(accountViewModel.account.currentBalance.withCommas(decimalPlace: 2))")
                    .foregroundColor(Color.navyBlue)
                    .font(.caption.bold())
                Spacer()
                if(accountViewModel.account.paymentReminder && accountViewModel.account.accountType != "Saving") {
                    Label("", systemImage: "bell.fill")
                        .foregroundColor(Color.navyBlue)
                        .font(.caption.bold())
                    Text("\(accountViewModel.account.paymentDate)")
                        .foregroundColor(Color.navyBlue)
                        .font(.caption.bold())
                } else if(accountViewModel.account.accountType != "Saving") {
                    Label("", systemImage: "bell.slash.fill")
                        .foregroundColor(Color.navyBlue)
                        .font(.caption.bold())
                }
            }
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
        .padding(.horizontal)
        .frame(width: 360,height: 50)
        .padding(8)
        .background(Color.white)
    }
    
    func getTotalChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? (accountViewModel.accountLastTwoTransactionList[0].balanceChange) : 0.0
    }
    
    func getOneDayPercentageChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? ((getTotalChangeForNonSymbol() * 100 ) / accountViewModel.accountLastTwoTransactionList[1].currentBalance) : 0.0
    }
}
