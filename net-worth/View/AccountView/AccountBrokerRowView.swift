//
//  AccountBrokerRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerRowView: View {
    
    var account: AccountInBroker
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(account.name)
                    .font(.headline)
                    .foregroundColor(Color.theme.primaryText)
                    .padding(.horizontal)
                HStack {
                    Text("Qty. " + account.currentUnit.withCommas(decimalPlace: 4))
                        .font(.system(size: 12))
                        .foregroundColor(Color.theme.secondaryText)
                        .padding(.leading)
                }
                HStack {
                    Text(account.balance.currentDayValue.dateTime.UTCToLocalDate().format())
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.system(size: 10).italic())
                        .padding(.leading)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                HStack {
                    Text(SettingsController().getDefaultCurrency().code)
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.secondaryText)
                    Text(account.balance.currentDayValue.value.withCommas(decimalPlace: 2))
                        .font(.headline)
                        .foregroundColor(Color.theme.primaryText)
                }
                .padding(.horizontal)
                if(getOneDayChange() > 0) {
                    HStack {
                        Text(getOneDayChange().withCommas(decimalPlace: 2))
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.green)
                        Text("(+" + getOneDayPercentageChange() + ")")
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.green)
                    }
                    .padding(.horizontal)
                } else if(getOneDayChange() < 0) {
                    HStack {
                        Text(getOneDayChange().withCommas(decimalPlace: 2))
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.red)
                        Text("(" + getOneDayPercentageChange() + ")")
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.red)
                    }
                    .padding(.horizontal)
                } else {
                    Text("")
                }
            }
        }
    }
    
    private func getOneDayChange() -> Double {
        return areOneDayTransactions() ? account.balance.currentDayValue.value - account.balance.previousDayValue.value : 0.0
    }
    
    private func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.balance.previousDayValue.value, currentBalance: account.balance.currentDayValue.value)
    }
    
    private func areOneDayTransactions() -> Bool {
        return account.name != "" && account.balance.currentDayValue.dateTime.UTCToLocalDate() >= Date.now.addingTimeInterval(-86400)
    }
}
