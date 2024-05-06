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
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    var balanceAccount: BalanceAccount
    
    init(accountType: String, isWatchListCardView: Bool, watchList: Watch, accountViewModel: AccountViewModel) {
        self.accountType = accountType
        self.isWatchListCardView = isWatchListCardView
        self.watchList = watchList
        self.accountViewModel = accountViewModel
        let accountList = accountViewModel.sectionContent(key: accountType, searchKeyword: "")
        var currentDayValue = 0.0
        var previousDayValue = 0.0
        
        for account in accountList {
            currentDayValue += account.balance.currentDayValue
            previousDayValue += account.balance.previousDayValue
        }
        balanceAccount = BalanceAccount(currentDayValue: currentDayValue, previousDayValue: previousDayValue)
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
    }
    
    private func getOneDayChange() -> Double {
        return balanceAccount.currentDayValue - balanceAccount.previousDayValue
    }
    func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: balanceAccount.previousDayValue, currentBalance: balanceAccount.currentDayValue)
    }
}
