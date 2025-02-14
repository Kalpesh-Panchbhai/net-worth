//
//  TotalAccountBalanceCardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 13/02/23.
//

import SwiftUI

struct BalanceCardView: View {
    
    var accountType: String
    var isWatchListCardView: Bool
    
    @State var watchList: WatchRestModel
    @State var balanceAccount: AccountValue
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    init(accountType: String, isWatchListCardView: Bool, watchList: WatchRestModel) {
        self.accountType = accountType
        self.isWatchListCardView = isWatchListCardView
        self.watchList = watchList
        self.balanceAccount = AccountValue()
    }
    
    var body: some View {
        ZStack {
            Color.theme.foreground
            VStack(alignment: .center) {
                HStack {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                    Text("\(balanceAccount.currentValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                }
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
                        Text("+\(getOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 14))
                            .bold()
                        Text("(+\(getOneDayPercentageChange()))")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 14))
                            .bold()
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
                        Text("\(getOneDayChange().withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 14))
                            .bold()
                        Text("(\(getOneDayPercentageChange()))")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 14))
                            .bold()
                    }
                }
            }
        }
        .onAppear {
            if(isWatchListCardView) {
//                let accountList = accountViewModel.accountList.filter {
//                    return watchList.accountList.contains($0.id)
//                }
//                var currentDayValue = 0.0
//                var previousDayValue = 0.0
//                
//                for account in accountList {
//                    currentDayValue += account.value.currentBalance
//                    if(areOneDayTransactions(account: account)) {
//                        previousDayValue += account.value.previousBalance
//                    } else {
//                        previousDayValue += account.value.currentBalance
//                    }
//                }
//                balanceAccount = AccountValue(currentBalance: currentDayValue, previousBalance: previousDayValue)
            } else {
                var accountList = [AccountRestModel]()
                if(accountType.elementsEqual("Net Worth")) {
                    accountList = accountViewModel.accountList
                } else {
                    accountList = accountViewModel.sectionContent(key: accountType, searchKeyword: "")
                }
                var currentDayValue = 0.0
                var previousDayValue = 0.0
                
                for account in accountList {
                    currentDayValue += account.value.currentValue
                    if(areOneDayTransactions(account: account)) {
                        previousDayValue += account.value.previousValue
                    } else {
                        previousDayValue += account.value.currentValue
                    }
                }
                balanceAccount = AccountValue(currentValue: currentDayValue, previousValue: previousDayValue)
            }
        }
    }
    
    private func getOneDayChange() -> Double {
        return balanceAccount.currentValue - balanceAccount.previousValue
    }
    
    private func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: balanceAccount.previousValue, currentBalance: balanceAccount.currentValue)
    }
    
    private func areOneDayTransactions(account: AccountRestModel) -> Bool {
        return true
//        return account.name != "" && account.value.currentBalance.dateTime.UTCToLocalDate() >= Date.now.addingTimeInterval(-86400)
    }
}
