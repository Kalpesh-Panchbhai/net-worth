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
            Color.white
            VStack(alignment: .center) {
                HStack {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(Color.navyBlue)
                        .bold()
                    Text("\(accountViewModel.totalBalance.currentValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.navyBlue)
                        .bold()
                }
                HStack {
                    if(accountViewModel.totalBalance.oneDayChange >= 0) {
                        if(accountViewModel.totalBalance.oneDayChange > 0) {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.green)
                                .font(.system(size: 14)
                                    .bold())
                        }
                        Text("\(accountViewModel.totalBalance.oneDayChange.withCommas(decimalPlace: 2))")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                            .bold()
                        Text("(\(getOneDayPercentageChange().withCommas(decimalPlace: 2))%)")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                            .bold()
                    } else {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.red)
                            .font(.system(size: 14)
                                .bold())
                        Text("\(accountViewModel.totalBalance.oneDayChange.withCommas(decimalPlace: 2))")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .bold()
                        Text("(\(getOneDayPercentageChange().withCommas(decimalPlace: 2))%)")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .bold()
                    }
                }
            }
            .padding()
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
