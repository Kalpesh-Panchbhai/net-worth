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
    
    @State var watchList: Watch
    @State var balanceAccount: BalanceAccount
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    init(accountType: String, isWatchListCardView: Bool, watchList: Watch) {
        self.accountType = accountType
        self.isWatchListCardView = isWatchListCardView
        self.watchList = watchList
        self.balanceAccount = BalanceAccount()
    }
    
    var body: some View {
        ZStack {
            Color.theme.foreground
            VStack(alignment: .center) {
                HStack {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                    Text("\(balanceAccount.currentDayValue.withCommas(decimalPlace: 2))")
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
                let accountList = accountViewModel.accountList.filter {
                    return watchList.accountList.contains($0.id)
                }
                var currentDayValue = 0.0
                var previousDayValue = 0.0
                
                for account in accountList {
                    currentDayValue += account.balance.currentDayValue
                    previousDayValue += account.balance.previousDayValue
                }
                balanceAccount = BalanceAccount(currentDayValue: currentDayValue, previousDayValue: previousDayValue)
            } else {
                var accountList = [Account]()
                if(accountType.elementsEqual("Net Worth")) {
                    accountList = accountViewModel.accountList
                } else {
                    accountList = accountViewModel.sectionContent(key: accountType, searchKeyword: "")
                }
                var currentDayValue = 0.0
                var previousDayValue = 0.0
                
                for account in accountList {
                    currentDayValue += account.balance.currentDayValue
                    previousDayValue += account.balance.previousDayValue
                }
                balanceAccount = BalanceAccount(currentDayValue: currentDayValue, previousDayValue: previousDayValue)
            }
        }
    }
    
    private func getOneDayChange() -> Double {
        return balanceAccount.currentDayValue - balanceAccount.previousDayValue
    }
    func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: balanceAccount.previousDayValue, currentBalance: balanceAccount.currentDayValue)
    }
}
