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
                        Text("(+" + getOneDayPercentageChangeForBroker() + ")")
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.green)
                    }
                    .padding(.horizontal)
                } else if(getOneDayChange() < 0) {
                    HStack {
                        Text(getOneDayChange().withCommas(decimalPlace: 2))
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.red)
                        Text("(" + getOneDayPercentageChangeForBroker() + ")")
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.red)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func getOneDayChange() -> Double {
        return account.balance.currentDayValue.value - account.balance.previousDayValue.value
    }
    private func getOneDayPercentageChangeForBroker() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.balance.previousDayValue.value, currentBalance: account.balance.currentDayValue.value)
    }
}
