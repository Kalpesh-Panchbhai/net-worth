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
    
    @StateObject var accountViewModel: AccountViewModel
    
    var body: some View {
        ZStack {
            Color.theme.foreground
            VStack(alignment: .center) {
                HStack {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                    Text("\(accountViewModel.totalBalance.currentValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                }
                HStack {
                    if(accountViewModel.totalBalance.oneDayChange >= 0) {
                        if(accountViewModel.totalBalance.oneDayChange > 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.green.opacity(0.2))
                                    .frame(width: 20, height: 20)
                                Image(systemName: "arrow.up")
                                    .foregroundColor(Color.theme.green)
                                    .font(.system(size: 14)
                                    .bold())
                            }
                            
                        }
                        Text("\(accountViewModel.totalBalance.oneDayChange.withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 14))
                            .bold()
                        Text("(\(getOneDayPercentageChange().withCommas(decimalPlace: 2))%)")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 14))
                            .bold()
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.theme.red.opacity(0.2))
                                .frame(width: 20, height: 20)
                            Image(systemName: "arrow.down")
                                .foregroundColor(Color.theme.red)
                                .font(.system(size: 14)
                                .bold())
                        }
                        Text("\(accountViewModel.totalBalance.oneDayChange.withCommas(decimalPlace: 2))")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 14))
                            .bold()
                        Text("(\(getOneDayPercentageChange().withCommas(decimalPlace: 2))%)")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 14))
                            .bold()
                    }
                }
            }
        }
        .onAppear {
            Task.init {
                if(!isWatchListCardView) {
                    await accountViewModel.getAccountList()
                    await accountViewModel.getTotalBalance(accountList: accountViewModel.sectionContent(key: accountType, searchKeyword: ""))
                }
            }
        }
    }
    
    func getOneDayPercentageChange() -> Double {
        return (accountViewModel.totalBalance.oneDayChange) / (accountViewModel.totalBalance.currentValue - accountViewModel.totalBalance.oneDayChange) * 100
    }
}
