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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(accountType)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ColorTheme().primaryText)
                        
                    }
                    
                    HStack {
                        Text("1D Change: ")
                            .font(.system(size: 14))
                            .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                        
                        Text(SettingsController().getDefaultCurrency().symbol + getOneDayChange().abbreviated())
                            .font(.system(size: 18))
                            .foregroundColor(ColorTheme().primaryText)
                                
                        if(getOneDayChange() > 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.green.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowUpImageName)
                                    .foregroundColor(Color.theme.green)
                                    .font(.system(size: 14))
                            }
                            
                            Text(getOneDayPercentageChange())
                                .font(.system(size: 14))
                                .foregroundColor(ColorTheme().green)
                        } else if(getOneDayChange() < 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.red.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowDownImageName)
                                    .foregroundColor(Color.theme.red)
                                    .font(.system(size: 14))
                            }
                            
                            Text(getOneDayPercentageChange())
                                .font(.system(size: 14))
                                .foregroundColor(ColorTheme().red)
                        }
                    }
                }
            }
                    
            HStack {
                VStack(alignment: .leading) {
                    Text("Invested")
                        .font(.system(size: 14))
                        .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                    Text(SettingsController().getDefaultCurrency().symbol + balanceAccount.invested.abbreviated())
                        .font(.system(size: 16))
                        .foregroundColor(ColorTheme().primaryText)
                }
                        
                Spacer()
                        
                VStack(alignment: .leading) {
                    Text("Current Value")
                        .font(.system(size: 14))
                        .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                    Text(SettingsController().getDefaultCurrency().symbol + balanceAccount.currentValue.abbreviated())
                        .font(.system(size: 16))
                        .foregroundColor(ColorTheme().primaryText)
                }
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Gain/Loss")
                        .font(.system(size: 14))
                        .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                    HStack(spacing: 4) {
                        Text(SettingsController().getDefaultCurrency().symbol + getTotalChange().abbreviated())
                            .font(.system(size: 16))
                            .foregroundColor(ColorTheme().primaryText)
                        if(getTotalChange() > 0) {
                            Text(getTotalPercentageChange())
                                .font(.system(size: 14))
                                .foregroundColor(ColorTheme().green)
                        } else if(getTotalChange() < 0) {
                            Text(getTotalPercentageChange())
                                .font(.system(size: 14))
                                .foregroundColor(ColorTheme().red)
                        }
                    }
                }
            }
        }
        .onAppear {
            if(isWatchListCardView) {
                balanceAccount = AccountValue(currentValue: watchList.value.currentValue, previousValue: watchList.value.previousValue, invested: watchList.value.invested)
            } else {
                var accountList = [AccountRestModel]()
                if(accountType.elementsEqual("Net Worth")) {
                    accountList = accountViewModel.accountList
                } else {
                    accountList = accountViewModel.sectionContent(key: accountType, searchKeyword: "")
                }
                var currentDayValue = 0.0
                var previousDayValue = 0.0
                var invested = 0.0
                
                for account in accountList {
                    currentDayValue += account.value.currentValue
                    previousDayValue += account.value.previousValue
                    invested += account.value.invested
                }
                balanceAccount = AccountValue(currentValue: currentDayValue, previousValue: previousDayValue , invested: invested)
            }
        }
        .padding(16)
        .background(Color.theme.foreground)
        .cornerRadius(10)
    }
    
    private func getOneDayChange() -> Double {
        return balanceAccount.currentValue - balanceAccount.previousValue
    }
    
    private func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: balanceAccount.previousValue, currentBalance: balanceAccount.currentValue)
    }
    
    private func getTotalChange() -> Double {
        return balanceAccount.currentValue - balanceAccount.invested
    }
    
    private func getTotalPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: balanceAccount.invested, currentBalance: balanceAccount.currentValue)
    }
}
