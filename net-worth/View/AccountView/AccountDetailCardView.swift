//
//  AccountDetailCardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailCardView: View {
    
    var account: Account
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack {
                Text(account.currency)
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.caption)
                Text("\(account.balance.currentDayValue.withCommas(decimalPlace: 2))")
                    .foregroundColor(Color.theme.primaryText)
                    .font(.caption.bold())
                Spacer()
                if(!account.active) {
                    Text("(Closed)")
                        .foregroundColor(Color.theme.red)
                        .font(.caption2.italic())
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
            HStack {
                if(getTotalChangeForNonSymbol() > 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.green.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: ConstantUtils.arrowUpImageName)
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                    }
                    Text("+\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                    Text("(+\(getOneDayPercentageChangeForNonSymbol()))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                } else if(getTotalChangeForNonSymbol() < 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.red.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: ConstantUtils.arrowDownImageName)
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                    }
                    Text("\(getTotalChangeForNonSymbol().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                    Text("(\(getOneDayPercentageChangeForNonSymbol()))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .frame(width: 360,height: 50)
        .padding(8)
        .background(Color.theme.foreground)
    }
    
    func getTotalChangeForNonSymbol() -> Double {
        return account.balance.currentDayValue - account.balance.previousDayValue
    }
    
    func getOneDayPercentageChangeForNonSymbol() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.balance.previousDayValue, currentBalance: account.balance.currentDayValue)
    }
}
