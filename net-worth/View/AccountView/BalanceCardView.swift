//
//  TotalAccountBalanceCardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 13/02/23.
//

import SwiftUI

struct BalanceCardView: View {
    
    @StateObject var accountViewModel: AccountViewModel
    
    var accountType: String
    var isWatchListCardView: Bool
    @State var watchList: Watch
    
    var body: some View {
        ZStack {
            Color(#colorLiteral(red: 0.9058823529, green: 0.9490196078, blue: 0.9803921569, alpha: 1))
            VStack(alignment: .center) {
                HStack {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(.black)
                        .bold()
                    Text("\(accountViewModel.totalBalance.currentValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(.black)
                        .bold()
                }
                HStack {
                    if(accountViewModel.totalBalance.oneDayChange >= 0) {
                        Text("\(accountViewModel.totalBalance.oneDayChange.withCommas(decimalPlace: 2))")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                            .bold()
                        Text("(\(getOneDayPercentageChange().withCommas(decimalPlace: 2))%)")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                            .bold()
                    } else {
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
