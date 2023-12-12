//
//  CardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct AccountCardView: View {
    
    var accountID: String
    
    @StateObject var accountViewModel = AccountViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(accountViewModel.account.accountName)
                    .foregroundColor(Color.theme.primaryText)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.leading)
                Spacer()
                if(accountViewModel.account.accountType != "Broker") {
                    if(accountViewModel.account.active) {
                        if(accountViewModel.account.paymentReminder && accountViewModel.account.accountType != "Saving") {
                            Image(systemName: "bell.fill")
                                .foregroundColor(Color.theme.green.opacity(0.7))
                                .font(.caption)
                            Text("\(accountViewModel.account.paymentDate)")
                                .foregroundColor(Color.theme.green)
                                .font(.caption)
                        } else if(accountViewModel.account.accountType != "Saving") {
                            Image(systemName: "bell.slash.fill")
                                .foregroundColor(Color.theme.red.opacity(0.7))
                                .font(.caption)
                        }
                    } else {
                        Text(accountViewModel.account.accountType)
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            Spacer()
            Spacer()
            HStack(alignment: .center) {
                if(accountViewModel.account.accountType == "Broker") {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                    Text("\(accountViewModel.accountBrokerCurrentBalance.currentValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.primaryText)
                        .font(.caption.bold())
                } else {
                    Text(accountViewModel.account.currency)
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                    Text("\(accountViewModel.accountOneDayChange.currentValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.primaryText)
                        .font(.caption.bold())
                }
            }
            Spacer()
            HStack {
                if(accountViewModel.account.accountType == "Broker") {
                    if(calculateOneDayChange() > 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.green.opacity(0.2))
                                .frame(width: 17, height: 17)
                            Image(systemName: "arrow.up")
                                .foregroundColor(Color.theme.green)
                                .font(.system(size: 11).bold())
                        }
                        Text("+\(calculateOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 11).bold())
                        Text("(+\(calculatePercentChangeForOneDay()))")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 11).bold())
                    } else if(calculateOneDayChange() < 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.red.opacity(0.2))
                                .frame(width: 17, height: 17)
                            Image(systemName: "arrow.down")
                                .foregroundColor(Color.theme.red)
                                .font(.system(size: 11).bold())
                        }
                        Text("\(calculateOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 11).bold())
                        Text("(\(calculatePercentChangeForOneDay()))")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 11).bold())
                    } else {
                        Text("")
                    }
                } else {
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
            }
            Spacer()
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccount(id: accountID)
                if(accountViewModel.account.accountType == "Broker") {
                    await accountViewModel.getAccountInBrokerList(brokerID: accountID)
                    await accountViewModel.getBrokerAllAccountCurrentBalance(accountBrokerList: accountViewModel.accountsInBroker)
                } else {
                    await accountViewModel.getAccountLastOneDayChange(id: accountID)
                }
            }
        }
        .frame(width: 150, height: 80)
        .padding(8)
        .background(Color.theme.foreground)
        .cornerRadius(10)
    }
    
    private func getOneDayChange() -> Double {
        return accountViewModel.accountOneDayChange.oneDayChange
    }
    
    private func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: accountViewModel.accountOneDayChange.previousDayValue, currentBalance: accountViewModel.accountOneDayChange.currentValue)
    }
    
    private func calculateOneDayChange() -> Double {
        return accountViewModel.accountBrokerCurrentBalance.currentValue - accountViewModel.accountBrokerCurrentBalance.previousDayValue
    }
    
    private func calculatePercentChangeForOneDay() -> String {
        return CommonController.getGrowthPercentage(previousBalance: accountViewModel.accountBrokerCurrentBalance.previousDayValue, currentBalance: accountViewModel.accountBrokerCurrentBalance.currentValue)
    }
}
