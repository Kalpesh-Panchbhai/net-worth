//
//  CardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct AccountCardView: View {
    
    var account: Account
    
    @StateObject var accountViewModel = AccountViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(account.accountName)
                    .foregroundColor(Color.theme.primaryText)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.leading)
                Spacer()
                if(account.paymentReminder && account.accountType != "Saving") {
                    Image(systemName: "bell.fill")
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                    Text("\(account.paymentDate)")
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                } else if(account.accountType != "Saving") {
                    Image(systemName: "bell.slash.fill")
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                }
            }
            Spacer()
            Spacer()
            HStack(alignment: .center) {
                Text(account.currency)
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.caption)
                Text("\(account.currentBalance.withCommas(decimalPlace: 2))")
                    .foregroundColor(Color.theme.primaryText)
                    .font(.caption.bold())
            }
            Spacer()
            HStack {
                if(getTotalChangeForNonSymbol() >= 0) {
                    if(getTotalChangeForNonSymbol() > 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.green.opacity(0.2))
                                .frame(width: 17, height: 17)
                            Image(systemName: "arrow.up")
                                .foregroundColor(Color.theme.green)
                                .font(.system(size: 11).bold())
                        }
                    }
                    Text("\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.green)
                        .font(.system(size: 11).bold())
                    Text("(\(getOneDayPercentageChangeForNonSymbol().withCommas(decimalPlace: 2))%)")
                        .foregroundColor(Color.theme.green)
                        .font(.system(size: 11).bold())
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.theme.red.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: "arrow.down")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 11).bold())
                    }
                    Text("\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.red)
                        .font(.system(size: 11).bold())
                    Text("(\(getOneDayPercentageChangeForNonSymbol().withCommas(decimalPlace: 2))%)")
                        .foregroundColor(Color.theme.red)
                        .font(.system(size: 11).bold())
                }
            }
            Spacer()
        }
        .onAppear {
            Task.init {
                await accountViewModel.getLastTwoAccountTransactionList(id: account.id ?? "")
            }
        }
        .frame(width: 150, height: 100)
        .padding(8)
        .background(Color.theme.foreground)
        .cornerRadius(10)
    }
    
    func getTotalChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? (accountViewModel.accountLastTwoTransactionList[0].balanceChange) : 0.0
    }
    
    func getOneDayPercentageChangeForNonSymbol() -> Double {
        return accountViewModel.accountLastTwoTransactionList.count > 1 ? ((getTotalChangeForNonSymbol() * 100 ) / accountViewModel.accountLastTwoTransactionList[1].currentBalance) : 0.0
    }
}
