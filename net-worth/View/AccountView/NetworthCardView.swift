//
//  NetworthCardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 13/05/24.
//

import SwiftUI

struct NetworthCardView: View {
    
    @State var balanceAccount = BalanceAccount()
    @State var percent: Double = 0.0
    @State var percentChange: Double = 0.0
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    @EnvironmentObject var incomeViewModel: IncomeViewModel
    
    var body: some View {
        ZStack {
            Color.theme.foreground
            VStack(alignment: .center, content: {
                HStack {
                    Text("Net worth :")
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                    Text(percent.withCommas(decimalPlace: 2) + "%")
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                    if(percentChange > 0) {
                        ZStack {
                            Circle()
                                .fill(Color.theme.green.opacity(0.2))
                                .frame(width: 14, height: 14)
                            Image(systemName: ConstantUtils.arrowUpImageName)
                                .foregroundColor(Color.theme.green)
                                .font(.system(size: 10)
                                    .bold())
                        }
                        Text("(+\(percentChange.withCommas(decimalPlace: 2))%)")
                            .foregroundColor(Color.theme.green)
                            .font(.system(size: 12))
                            .bold()
                    } else if(percentChange < 0){
                        ZStack {
                            Circle()
                                .fill(Color.theme.red.opacity(0.2))
                                .frame(width: 20, height: 20)
                            Image(systemName: ConstantUtils.arrowDownImageName)
                                .foregroundColor(Color.theme.red)
                                .font(.system(size: 10)
                                    .bold())
                        }
                        Text("(+\(percentChange.withCommas(decimalPlace: 2))%)")
                            .foregroundColor(Color.theme.red)
                            .font(.system(size: 12))
                            .bold()
                    }
                }
            })
        }
        .onAppear {
            let accountList = accountViewModel.accountList
            var currentDayValue = 0.0
            var previousDayValue = 0.0
            
            for account in accountList {
                currentDayValue += account.balance.currentDayValue
                previousDayValue += account.balance.previousDayValue
            }
            balanceAccount = BalanceAccount(currentDayValue: currentDayValue, previousDayValue: previousDayValue)
            let totalIncome = incomeViewModel.incomeTotalAmount
            percent = balanceAccount.currentDayValue / totalIncome * 100
            percentChange = (balanceAccount.currentDayValue - balanceAccount.previousDayValue) / totalIncome * 100
        }
    }
}
