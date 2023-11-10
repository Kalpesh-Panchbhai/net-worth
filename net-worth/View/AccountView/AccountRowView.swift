//
//  AccountRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountRowView: View {
    
    var account: Account
    var fromWatchView: Bool = false
    
    @StateObject var accountViewModel = AccountViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(accountViewModel.account.accountName)
                    .foregroundColor(Color.theme.primaryText)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.leading)
                Text(!accountViewModel.account.active ? "(Closed)" : "")
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.caption2.italic())
                    .multilineTextAlignment(.leading)
                if(fromWatchView) {
                    Spacer()
                    Text(accountViewModel.account.accountType)
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
            HStack {
                Text(accountViewModel.account.currency)
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.caption)
                Text("\(accountViewModel.accountOneDayChange.currentValue.withCommas(decimalPlace: 2))")
                    .foregroundColor(Color.theme.primaryText)
                    .font(.caption.bold())
            }
            Spacer()
            HStack {
                if(getOneDayChange() >= 0) {
                    if(getOneDayChange() > 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.green.opacity(0.2))
                                .frame(width: 17, height: 17)
                            Image(systemName: "arrow.up")
                                .foregroundColor(Color.theme.green)
                                .font(.caption.bold())
                        }
                    }
                    Text("+\(getOneDayChange().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                    Text("(+\(getOneDayPercentageChange()))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                    Spacer()
                    if(accountViewModel.account.paymentReminder && accountViewModel.account.accountType != "Saving" && accountViewModel.account.active) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                        Text("\(accountViewModel.account.paymentDate)")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                    } else if(accountViewModel.account.accountType != "Saving" && accountViewModel.account.active) {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.theme.red.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: "arrow.down")
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                    }
                    Text("\(getOneDayChange().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                    Text("(\(getOneDayPercentageChange()))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                    Spacer()
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
                }
            }
            Spacer()
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccount(id: account.id!)
                await accountViewModel.getAccountLastOneDayChange(id: account.id!)
            }
        }
        .padding(.horizontal)
        .background(Color.theme.foreground)
        .cornerRadius(10)
    }
    
    func getOneDayChange() -> Double {
        return accountViewModel.accountOneDayChange.oneDayChange
    }
    
    func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: accountViewModel.accountOneDayChange.previousDayValue, currentBalance: accountViewModel.accountOneDayChange.currentValue)
    }
}
