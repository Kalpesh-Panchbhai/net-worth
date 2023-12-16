//
//  AccountRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountRowView: View {
    
    var accountID: String
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
                if(accountViewModel.account.accountType == ConstantUtils.brokerAccountType) {
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
                if(accountViewModel.account.accountType == ConstantUtils.brokerAccountType) {
                    if(accountViewModel.accountBrokerCurrentBalance.oneDayChange >= 0) {
                        if(accountViewModel.accountBrokerCurrentBalance.oneDayChange > 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.green.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowUpImageName)
                                    .foregroundColor(Color.theme.green)
                                    .font(.caption.bold())
                            }
                        }
                        Text("+\(accountViewModel.accountBrokerCurrentBalance.oneDayChange.withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                        Text("(+\(getOneDayPercentageChangeForBroker()))")
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                        Spacer()
                    } else {
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
                        Spacer()
                    }
                } else {
                    if(accountViewModel.accountOneDayChange.oneDayChange >= 0) {
                        if(accountViewModel.accountOneDayChange.oneDayChange > 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.green.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowUpImageName)
                                    .foregroundColor(Color.theme.green)
                                    .font(.caption.bold())
                            }
                        }
                        Text("+\(accountViewModel.accountOneDayChange.oneDayChange.withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                        Text("(+\(getOneDayPercentageChangeForNonBroker()))")
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                        Spacer()
                        if(accountViewModel.account.paymentReminder && accountViewModel.account.accountType != ConstantUtils.savingAccountType && accountViewModel.account.active) {
                            Image(systemName: ConstantUtils.notificationOnImageName)
                                .foregroundColor(Color.theme.secondaryText)
                                .font(.caption)
                            Text("\(accountViewModel.account.paymentDate)")
                                .foregroundColor(Color.theme.secondaryText)
                                .font(.caption)
                        } else if(accountViewModel.account.accountType != ConstantUtils.savingAccountType && accountViewModel.account.active) {
                            Image(systemName: ConstantUtils.notificationOffImageName)
                                .foregroundColor(Color.theme.secondaryText)
                                .font(.caption)
                        }
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.theme.red.opacity(0.2))
                                .frame(width: 17, height: 17)
                            Image(systemName: ConstantUtils.arrowDownImageName)
                                .foregroundColor(Color.theme.red)
                                .font(.caption.bold())
                        }
                        Text("\(accountViewModel.accountOneDayChange.oneDayChange.withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                        Text("(\(getOneDayPercentageChangeForNonBroker()))")
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                        Spacer()
                        if(accountViewModel.account.paymentReminder && accountViewModel.account.accountType != ConstantUtils.savingAccountType) {
                            Image(systemName: ConstantUtils.notificationOnImageName)
                                .foregroundColor(Color.theme.secondaryText)
                                .font(.caption)
                            Text("\(accountViewModel.account.paymentDate)")
                                .foregroundColor(Color.theme.secondaryText)
                                .font(.caption)
                        } else if(accountViewModel.account.accountType != ConstantUtils.savingAccountType) {
                            Image(systemName: ConstantUtils.notificationOffImageName)
                                .foregroundColor(Color.theme.secondaryText)
                                .font(.caption)
                        }
                    }
                }
            }
            Spacer()
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccount(id: accountID)
                if(accountViewModel.account.accountType == ConstantUtils.brokerAccountType) {
                    await accountViewModel.getAccountInBrokerList(brokerID: accountID)
                    await accountViewModel.getCurrentBalanceOfAllAccountsInABroker(accountBrokerList: accountViewModel.accountsInBroker)
                } else {
                    await accountViewModel.getAccountLastOneDayChange(id: accountID)
                }
            }
        }
        .padding(.horizontal)
        .background(Color.theme.foreground)
        .cornerRadius(10)
    }
    
    private func getOneDayPercentageChangeForNonBroker() -> String {
        return CommonController.getGrowthPercentage(previousBalance: accountViewModel.accountOneDayChange.previousDayValue, currentBalance: accountViewModel.accountOneDayChange.currentValue)
    }
    
    private func getOneDayPercentageChangeForBroker() -> String {
        return CommonController.getGrowthPercentage(previousBalance: accountViewModel.accountBrokerCurrentBalance.previousDayValue, currentBalance: accountViewModel.accountBrokerCurrentBalance.currentValue)
    }
}
