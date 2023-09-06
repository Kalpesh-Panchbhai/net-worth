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
                Text(accountViewModel.account.currency)
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.caption)
                Text("\(accountViewModel.account.currentBalance.withCommas(decimalPlace: 2))")
                    .foregroundColor(Color.theme.primaryText)
                    .font(.caption.bold())
                Spacer()
                if(accountViewModel.account.active) {
                    if(accountViewModel.account.paymentReminder && accountViewModel.account.accountType != "Saving") {
                        Image(systemName: "bell.fill")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                        Text("\(accountViewModel.account.paymentDate)")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                    } else if(accountViewModel.account.accountType != "Saving") {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                    }
                } else {
                    Text("(Closed)")
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption2.italic())
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
            HStack {
                if(getTotalChangeForNonSymbol() > 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.green.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: "arrow.up")
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                    }
                    Text("+\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                    Text("(+\(getOneDayPercentageChangeForNonSymbol()))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                } else if(getTotalChangeForNonSymbol() < 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.red.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: "arrow.down")
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                    }
                    Text("\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                    Text("(\(getOneDayPercentageChangeForNonSymbol()))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .frame(width: 360,height: 50)
        .padding(8)
        .background(Color.theme.foreground)
    }
    
    func getTotalChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? (accountViewModel.accountLastTwoTransactionList[0].balanceChange) : 0.0
    }
    
    func getOneDayPercentageChangeForNonSymbol() -> String {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? (CommonController.getGrowthPercentage(previousBalance: accountViewModel.accountLastTwoTransactionList[1].currentBalance, currentBalance: accountViewModel.accountLastTwoTransactionList[0].currentBalance)) : "0.0"
    }
}
