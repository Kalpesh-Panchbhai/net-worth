//
//  CardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct AccountCardView: View {
    
    var account: Account
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(account.accountName)
                    .foregroundColor(Color.theme.primaryText)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.leading)
                Spacer()
                if(account.accountType != ConstantUtils.brokerAccountType) {
                    if(!account.active) {
                        Text(account.accountType)
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            Spacer()
            Spacer()
            HStack(alignment: .center) {
                if(account.accountType == ConstantUtils.brokerAccountType) {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                    Text("\(account.balance.currentDayValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.primaryText)
                        .font(.caption.bold())
                } else {
                    Text(account.currency)
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                    Text("\(account.balance.currentDayValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.primaryText)
                        .font(.caption.bold())
                }
            }
            Spacer()
            HStack {
                if(account.accountType == ConstantUtils.brokerAccountType) {
                    if(getOneDayChange() > 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.green.opacity(0.2))
                                .frame(width: 17, height: 17)
                            Image(systemName: ConstantUtils.arrowUpImageName)
                                .foregroundColor(Color.theme.green)
                                .font(.system(size: 11).bold())
                        }
                        Text("+\(getOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 11).bold())
                        Text("(+\(getOneDayPercentage()))")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 11).bold())
                    } else if(getOneDayChange() < 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.red.opacity(0.2))
                                .frame(width: 17, height: 17)
                            Image(systemName: ConstantUtils.arrowDownImageName)
                                .foregroundColor(Color.theme.red)
                                .font(.system(size: 11).bold())
                        }
                        Text("\(getOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 11).bold())
                        Text("(\(getOneDayPercentage()))")
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
                            Image(systemName: ConstantUtils.arrowUpImageName)
                                .foregroundColor(Color.theme.green)
                                .font(.system(size: 11).bold())
                        }
                        Text("+\(getOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 11).bold())
                        Text("(+\(getOneDayPercentage()))")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 11).bold())
                    } else if(getOneDayChange() < 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.red.opacity(0.2))
                                .frame(width: 17, height: 17)
                            Image(systemName: ConstantUtils.arrowDownImageName)
                                .foregroundColor(Color.theme.red)
                                .font(.system(size: 11).bold())
                        }
                        Text("\(getOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 11).bold())
                        Text("(\(getOneDayPercentage()))")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 11).bold())
                    } else {
                        Text("")
                    }
                }
            }
            Spacer()
        }
        //        .onAppear {
        //            Task.init {
        //                await accountViewModel.getAccount(id: accountID)
        //                if(accountViewModel.account.accountType == ConstantUtils.brokerAccountType) {
        //                    await accountViewModel.getAccountInBrokerList(brokerID: accountID)
        //                    await accountViewModel.getCurrentBalanceOfAllAccountsInABroker(accountBrokerList: accountViewModel.accountsInBroker)
        //                } else {
        //                    await accountViewModel.getAccountLastOneDayChange(id: accountID)
        //                }
        //            }
        //        }
        .frame(width: 150, height: 80)
        .padding(8)
        .background(Color.theme.foreground)
        .cornerRadius(10)
    }
    
    private func getOneDayPercentage() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.balance.previousDayValue, currentBalance: account.balance.currentDayValue)
    }
    
    private func getOneDayChange() -> Double {
        return account.balance.currentDayValue - account.balance.previousDayValue
    }
    
}
