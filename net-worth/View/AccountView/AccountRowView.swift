//
//  AccountRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountRowView: View {
    
    var account: AccountRestModel
    var fromWatchView: Bool = false
    var isInActiveAccount: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(account.accountName)
                    .foregroundColor(Color.theme.primaryText)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.leading)
                if(!isInActiveAccount) {
                    Text(!account.active ? "(Closed)" : "")
                        .foregroundColor(Color.theme.red)
                        .font(.caption2.italic())
                        .multilineTextAlignment(.leading)
                }
                if(fromWatchView) {
                    Spacer()
                    Text(account.accountType)
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption.italic())
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
            HStack {
                if(account.accountType == ConstantUtils.brokerAccountType) {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                    Text("\(account.value.currentDayValue.value.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.primaryText)
                        .font(.caption.bold())
                } else {
                    Text(account.currency)
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                    Text("\(account.value.currentDayValue.value.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.primaryText)
                        .font(.caption.bold())
                }
            }
            Spacer()
            HStack {
                if(account.accountType == ConstantUtils.brokerAccountType) {
                    if(getOneDayChange() >= 0) {
                        if(getOneDayChange() > 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.green.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowUpImageName)
                                    .foregroundColor(Color.theme.green)
                                    .font(.caption.bold())
                            }
                        }
                        Text("+\(getOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                        Text("(+\(getOneDayPercentageChange()))")
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
                        Text("\(getOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                        Text("(\(getOneDayPercentageChange()))")
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                        Spacer()
                    }
                } else {
                    if(getOneDayChange() > 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.green.opacity(0.2))
                                .frame(width: 17, height: 17)
                            Image(systemName: ConstantUtils.arrowUpImageName)
                                .foregroundColor(Color.theme.green)
                                .font(.caption.bold())
                        }
                        Text("+\(getOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                        Text("(+\(getOneDayPercentageChange()))")
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                        Spacer()
                    } else if(getOneDayChange() < 0){
                        ZStack {
                            Circle()
                                .fill(Color.theme.red.opacity(0.2))
                                .frame(width: 17, height: 17)
                            Image(systemName: ConstantUtils.arrowDownImageName)
                                .foregroundColor(Color.theme.red)
                                .font(.caption.bold())
                        }
                        Text("\(getOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                        Text("(\(getOneDayPercentageChange()))")
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                        Spacer()
                    } else {
                        Text("")
                        Spacer()
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .background(Color.theme.foreground)
        .cornerRadius(10)
    }
    
    private func getOneDayChange() -> Double {
        return areOneDayTransactions() ? account.value.currentDayValue.value - account.value.previousDayValue.value : 0.0
    }
    
    private func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.value.previousDayValue.value, currentBalance: account.value.currentDayValue.value)
    }
    
    private func areOneDayTransactions() -> Bool {
        return account.accountName != "" && account.value.currentDayValue.dateTime.UTCToLocalDate() >= Date.now.addingTimeInterval(-86400)
    }
}
