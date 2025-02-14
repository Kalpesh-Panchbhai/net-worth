//
//  WatchRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 20/07/23.
//

import SwiftUI

struct WatchViewRow: View {
    
    var watch: WatchRestModel
    @State var balance = AccountValue()
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Spacer()
                Text(watch.name)
                    .foregroundColor(Color.theme.primaryText)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.leading)
                Spacer()
                HStack {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(Color.theme.secondaryText)
                        .font(.caption)
                    Text("\(balance.currentValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.primaryText)
                        .font(.caption.bold())
                }
                Spacer()
                HStack {
                    if(getOneDayChange() > 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.green.opacity(0.2))
                                .frame(width: 20, height: 20)
                            Image(systemName: ConstantUtils.arrowUpImageName)
                                .foregroundColor(Color.theme.green)
                                .font(.system(size: 14)
                                    .bold())
                        }
                        Text("+" + getOneDayChange().withCommas(decimalPlace: 2))
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                        Text("(+\(getOneDayPercentageChange()))")
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                    } else if(getOneDayChange() < 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.red.opacity(0.2))
                                .frame(width: 20, height: 20)
                            Image(systemName: ConstantUtils.arrowDownImageName)
                                .foregroundColor(Color.theme.red)
                                .font(.system(size: 14)
                                    .bold())
                        }
                        Text(getOneDayChange().withCommas(decimalPlace: 2))
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                        Text("(\(getOneDayPercentageChange()))")
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                    } else {
                        Text("")
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            Task.init {
//                balance = AccountValue(currentBalance: 0.0, previousBalance: 0.0)
//                let accountList = watch.accountList.map { id in
//                    return accountViewModel.accountList.filter {
//                        return $0.id == id
//                    }.first ?? AccountRestModel(balance: AccountValue())
//                }
//                for account in accountList {
//                    self.balance.currentBalance += account.value.currentBalance
//                    if(areOneDayTransactions(account: account)) {
//                        self.balance.previousBalance += account.value.previousBalance
//                    } else {
//                        self.balance.previousBalance += account.value.currentBalance
//                    }
//                }
            }
        }
        .background(Color.theme.foreground)
    }
    
    private func getOneDayChange() -> Double {
        return balance.currentValue - balance.previousValue
    }
    
    private func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: balance.previousValue, currentBalance: balance.currentValue)
    }
    
    private func areOneDayTransactions(account: AccountRestModel) -> Bool {
        return true
//        return account.name != "" && account.value.currentBalance.dateTime.UTCToLocalDate() >= Date.now.addingTimeInterval(-86400)
    }
}
