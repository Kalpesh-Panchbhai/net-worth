//
//  AccountBrokerRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerRowView: View {
    
    var brokerID: String
    var accountID: String
    
    @StateObject var financeViewModel = FinanceViewModel()
    @StateObject var accountViewModel = AccountViewModel()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(accountViewModel.accountBroker.name)
                    .font(.headline)
                    .foregroundColor(Color.theme.primaryText)
                    .padding(.horizontal)
                HStack {
                    Text("Units : " + accountViewModel.accountBroker.currentUnit.withCommas(decimalPlace: 2))
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
                    Text(accountViewModel.accountBrokerCurrentBalance.currentValue.withCommas(decimalPlace: 2))
                        .font(.headline)
                        .foregroundColor(Color.theme.primaryText)
                }
                .padding(.horizontal)
                if(calculateOneDayChange() > 0) {
                    HStack {
                        Text(calculateOneDayChange().withCommas(decimalPlace: 2))
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.green)
                        Text("(+" + calculatePercentChangeForOneDay() + ")")
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.green)
                    }
                    .padding(.horizontal)
                } else if(calculateOneDayChange() < 0) {
                    HStack {
                        Text(calculateOneDayChange().withCommas(decimalPlace: 2))
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.red)
                        Text("(" + calculatePercentChangeForOneDay() + ")")
                            .font(.system(size: 12))
                            .foregroundColor(Color.theme.red)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear(perform: {
            Task.init {
                await accountViewModel.getBrokerAccount(brokerID: brokerID, accountID: accountID)
                let symbol = accountViewModel.accountBroker.symbol
                await financeViewModel.getSymbolDetail(symbol: symbol)
                await accountViewModel.getBrokerAccountCurrentBalance(accountBroker: accountViewModel.accountBroker)
            }
        })
    }
    
    private func calculateOneDayChange() -> Double {
        return accountViewModel.accountBrokerCurrentBalance.currentValue - accountViewModel.accountBrokerCurrentBalance.previousDayValue
    }
    
    private func calculatePercentChangeForOneDay() -> String {
        return CommonController.getGrowthPercentage(previousBalance: accountViewModel.accountBrokerCurrentBalance.previousDayValue, currentBalance: accountViewModel.accountBrokerCurrentBalance.currentValue)
    }
}
