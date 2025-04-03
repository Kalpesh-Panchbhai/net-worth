//
//  AccountBrokerRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerRowView: View {
    
    var account: AccountInBrokerRestModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(account.name)
                    .font(.headline)
                    .foregroundColor(Color.theme.primaryText)
                    .padding(.horizontal)
                Text("Invested " + SettingsController().getDefaultCurrency().code + " " + account.value.invested.withCommas(decimalPlace: 2))
                    .font(.system(size: 12))
                    .foregroundColor(Color.theme.secondaryText)
                    .padding(.horizontal)
                Text("Qty. " + account.currentUnit.withCommas(decimalPlace: 4))
                    .font(.system(size: 10))
                    .foregroundColor(Color.theme.secondaryText)
                    .padding(.horizontal)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(SettingsController().getDefaultCurrency().code + " " + account.value.currentValue.withCommas(decimalPlace: 2))
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.primaryText)
                    .padding(.horizontal)
                if(getTotalChange() > 0) {
                    Text(getTotalChange().withCommas(decimalPlace: 2) + " " + "(+" + getTotalPercentageChange() + ")")
                        .font(.system(size: 12))
                        .foregroundColor(Color.theme.green)
                        .padding(.horizontal)
                } else if(getTotalChange() < 0) {
                    Text(getTotalChange().withCommas(decimalPlace: 2) + " " + "(" + getTotalPercentageChange() + ")")
                        .font(.system(size: 12))
                        .foregroundColor(Color.theme.red)
                        .padding(.horizontal)
                } else {
                    Text("")
                }
                if(getOneDayChange() > 0) {
                    Text(getOneDayChange().withCommas(decimalPlace: 2) + " " + "(+" + getOneDayPercentageChange() + ")")
                        .font(.system(size: 12))
                        .foregroundColor(Color.theme.green)
                        .padding(.horizontal)
                } else if(getOneDayChange() < 0) {
                    Text(getOneDayChange().withCommas(decimalPlace: 2) + " " + "(" + getOneDayPercentageChange() + ")")
                        .font(.system(size: 12))
                        .foregroundColor(Color.theme.red)
                        .padding(.horizontal)
                } else {
                    Text("")
                }
            }
        }
    }
    
    private func getOneDayChange() -> Double {
        return account.value.currentValue - account.value.previousValue
    }
    
    private func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.value.previousValue, currentBalance: account.value.currentValue)
    }
    
    private func getTotalChange() -> Double {
        return account.value.currentValue - account.value.invested
    }
    
    private func getTotalPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.value.invested, currentBalance: account.value.currentValue)
    }
}
