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
                    Text(account.value.currentBalance.withCommas(decimalPlace: 2))
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
        return areOneDayTransactions() ? account.value.currentBalance - account.value.previousBalance : 0.0
    }
    
    private func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.value.previousBalance, currentBalance: account.value.currentBalance)
    }
    
    private func areOneDayTransactions() -> Bool {
        return true
//        return account.name != "" && account.balance.currentBalance.dateTime.UTCToLocalDate() >= Date.now.addingTimeInterval(-86400)
    }
}
