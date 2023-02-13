//
//  TotalAccountBalanceCardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 13/02/23.
//

import SwiftUI

struct TotalAccountBalanceCardView: View {
    
    @StateObject var accountViewModel: AccountViewModel
    
    var body: some View {
        ZStack {
            Color.black
            VStack(alignment: .center) {
                Spacer()
                Text("Total Net Worth")
                    .foregroundColor(.white)
                    .bold()
                HStack {
                    Text(SettingsController().getDefaultCurrency().code)
                        .foregroundColor(.white)
                        .bold()
                    Text("\(accountViewModel.totalBalance.currentValue.withCommas(decimalPlace: 2))")
                        .foregroundColor(.white)
                        .bold()
                }
                .padding()
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getTotalBalance()
            }
        }
        .frame(width: 350, height: 100)
        .padding(.horizontal, 20)
    }
}
