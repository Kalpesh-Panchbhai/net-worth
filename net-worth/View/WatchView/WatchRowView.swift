//
//  WatchRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 20/07/23.
//

import SwiftUI

struct WatchViewRow: View {
    
    var watch: Watch
    
    @StateObject var accountViewModel = AccountViewModel()
    @ObservedObject var watchViewModel = WatchViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(watch.accountName)
                    .foregroundColor(Color.theme.primaryText)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            HStack {
                Text(SettingsController().getDefaultCurrency().code)
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.caption)
                Text("\(accountViewModel.totalBalance.currentValue.withCommas(decimalPlace: 2))")
                    .foregroundColor(Color.theme.primaryText)
                    .font(.caption.bold())
                Spacer()
                Text("\(watch.accountID.count)")
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.caption.italic())
            }
            Spacer()
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
                    Text(accountViewModel.totalBalance.oneDayChange.withCommas(decimalPlace: 2))
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                    Text("(\(getOneDayPercentageChange()))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
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
                    Text(accountViewModel.totalBalance.oneDayChange.withCommas(decimalPlace: 2))
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                    Text("(\(getOneDayPercentageChange()))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                }
            }
            Spacer()
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
                await watchViewModel.getWatchList(id: watch.id!)
                await accountViewModel.getAccountsForWatchList(accountID: watchViewModel.watch.accountID)
                if(!watchViewModel.watch.accountID.isEmpty) {
                    await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                } else {
                    accountViewModel.totalBalance = Balance(currentValue: 0.0)
                }
                
            }
        }
        .background(Color.theme.foreground)
        .cornerRadius(10)
    }
    
    func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: accountViewModel.totalBalance.currentValue - accountViewModel.totalBalance.oneDayChange, currentBalance: accountViewModel.totalBalance.currentValue)
    }
    
}
