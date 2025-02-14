//
//  CardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/02/23.
//

import SwiftUI

struct AccountCardView: View {
    
    var account: AccountRestModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(account.name)
                    .foregroundColor(Color.theme.primaryText)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.leading)
                Spacer()
                if(account.type != ConstantUtils.brokerAccountType) {
                    if(!account.active) {
                        Text(account.type)
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            Spacer()
            HStack(alignment: .center) {
                if(account.type == ConstantUtils.brokerAccountType) {
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
                if(account.type == ConstantUtils.brokerAccountType) {
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
        }
        .frame(height: 80)
        .padding(8)
        .background(Color.theme.foreground)
        .cornerRadius(10)
    }
    
    private func getOneDayPercentage() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.value.previousDayValue.value, currentBalance: account.value.currentDayValue.value)
    }
    
    private func getOneDayChange() -> Double {
        return areOneDayTransactions() ? account.value.currentDayValue.value - account.value.previousDayValue.value : 0.0
    }
    
    private func areOneDayTransactions() -> Bool {
        return account.value.currentDayValue.dateTime.UTCToLocalDate() >= Date.now.addingTimeInterval(-86400)
    }
    
}
