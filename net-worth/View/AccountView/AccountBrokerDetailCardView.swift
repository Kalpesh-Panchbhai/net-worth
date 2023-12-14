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
                if(accountViewModel.accountBrokerCurrentBalance.oneDayChange > 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.green.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: ConstantUtils.arrowUpImageName)
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                    }
                    Text("+\(accountViewModel.accountBrokerCurrentBalance.oneDayChange.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                    Text("(+\(getOneDayPercentageChangeForBroker()))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                } else if(accountViewModel.accountBrokerCurrentBalance.oneDayChange < 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.red.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: ConstantUtils.arrowDownImageName)
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                    }
                    Text("\(accountViewModel.accountBrokerCurrentBalance.oneDayChange.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                    Text("(\(getOneDayPercentageChangeForBroker()))")
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
    
    private func getOneDayPercentageChangeForBroker() -> String {
        return CommonController.getGrowthPercentage(previousBalance: accountViewModel.accountBrokerCurrentBalance.previousDayValue, currentBalance: accountViewModel.accountBrokerCurrentBalance.currentValue)
    }
}
