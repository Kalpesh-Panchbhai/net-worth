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
                if(account.active) {
                    if(account.paymentReminder && account.accountType != "Saving") {
                        Image(systemName: "bell.fill")
                            .foregroundColor(Color.theme.green.opacity(0.7))
                            .font(.caption)
                        Text("\(account.paymentDate)")
                            .foregroundColor(Color.theme.green)
                            .font(.caption)
                    } else if(account.accountType != "Saving") {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(Color.theme.red.opacity(0.7))
                            .font(.caption)
                    }
                } else {
                    Text(account.accountType)
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
            Spacer()
            HStack(alignment: .center) {
                Text(account.currency)
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.caption)
                Text("\(accountViewModel.accountOneDayChange.currentValue.withCommas(decimalPlace: 2))")
                    .foregroundColor(Color.theme.primaryText)
                    .font(.caption.bold())
            }
            Spacer()
            HStack {
                if(getOneDayChange() > 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.green.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: "arrow.up")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 11).bold())
                    }
                    Text("+\(getOneDayChange().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.green)
                        .font(.system(size: 11).bold())
                    Text("(+\(getOneDayPercentageChange()))")
                        .foregroundColor(Color.theme.green)
                        .font(.system(size: 11).bold())
                } else if(getOneDayChange() < 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.red.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: "arrow.down")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 11).bold())
                    }
                    Text("\(getOneDayChange().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.red)
                        .font(.system(size: 11).bold())
                    Text("(\(getOneDayPercentageChange()))")
                        .foregroundColor(Color.theme.red)
                        .font(.system(size: 11).bold())
                } else {
                    Text("")
                }
            }
            Spacer()
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountLastOneDayChange(id: account.id!)
            }
        }
        .frame(width: 150, height: 80)
        .padding(8)
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
