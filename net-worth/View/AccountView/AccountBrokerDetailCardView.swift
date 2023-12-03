//
//  AccountBrokerDetailCardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerDetailCardView: View {
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(SettingsController().getDefaultCurrency().code)
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.caption)
                Text("\(accountViewModel.accountBrokerCurrentBalance.currentValue.withCommas(decimalPlace: 2))")
                    .foregroundColor(Color.theme.primaryText)
                    .font(.caption.bold())
                Spacer()
            }
            Spacer()
            HStack {
                if(calculateOneDayChange() > 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.green.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: "arrow.up")
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                    }
                    Text("+\(calculateOneDayChange().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                    Text("(+\(calculatePercentChangeForOneDay()))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                } else if(calculateOneDayChange() < 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.red.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: "arrow.down")
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                    }
                    Text("\(calculateOneDayChange().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                    Text("(\(calculatePercentChangeForOneDay()))")
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
    
    private func calculateOneDayChange() -> Double {
        return accountViewModel.accountBrokerCurrentBalance.currentValue - accountViewModel.accountBrokerCurrentBalance.previousDayValue
    }
    
    private func calculatePercentChangeForOneDay() -> String {
        return CommonController.getGrowthPercentage(previousBalance: accountViewModel.accountBrokerCurrentBalance.previousDayValue, currentBalance: accountViewModel.accountBrokerCurrentBalance.currentValue)
    }
}
