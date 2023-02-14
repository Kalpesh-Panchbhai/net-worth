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
    
    var body: some View {
        ZStack {
            Color.black
            VStack(alignment: .center) {
                Spacer()
                Text("Total " + accountType.localizedCapitalized + " Balance")
                    .foregroundColor(.white)
                    .bold()
                    .padding()
                HStack {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(.white)
                        .bold()
                    Text("\(accountViewModel.totalBalance.currentValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(.white)
                        .bold()
                }
                HStack {
                    if(accountViewModel.totalBalance.oneDayChange >= 0) {
                        Text("\(accountViewModel.totalBalance.oneDayChange.withCommas(decimalPlace: 2))")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                            .bold()
                    } else {
                        Text("\(accountViewModel.totalBalance.oneDayChange.withCommas(decimalPlace: 2))")
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
                await accountViewModel.getTotalBalance()
            }
        }
    }
}
