//
//  AccountDetailCardView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailCardView: View {
    
    var account: AccountRestModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(account.currency)
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.caption)
                Text("\(account.value.currentValue.withCommas(decimalPlace: 2))")
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
            HStack {
                if(getTotalChange() > 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.green.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: ConstantUtils.arrowUpImageName)
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                    }
                    Text("+\(getTotalChange().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                    Text("(+\(getTotalPercentageChange()))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                } else if(getTotalChange() < 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.red.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: ConstantUtils.arrowDownImageName)
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                    }
                    Text("\(getTotalChange().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                    Text("(\(getTotalPercentageChange()))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                }
            }
            HStack {
                if(getOneDayChange() > 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.green.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: ConstantUtils.arrowUpImageName)
                            .foregroundColor(Color.theme.green)
                            .font(.caption.bold())
                    }
                    Text("+\(getOneDayChange().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                    Text("(+\(getOneDayPercentageChange()))")
                        .foregroundColor(Color.theme.green)
                        .font(.caption.bold())
                } else if(getOneDayChange() < 0) {
                    ZStack {
                        Circle()
                            .fill(Color.theme.red.opacity(0.2))
                            .frame(width: 17, height: 17)
                        Image(systemName: ConstantUtils.arrowDownImageName)
                            .foregroundColor(Color.theme.red)
                            .font(.caption.bold())
                    }
                    Text("\(getOneDayChange().withCommas(decimalPlace: 2))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                    Text("(\(getOneDayPercentageChange()))")
                        .foregroundColor(Color.theme.red)
                        .font(.caption.bold())
                }
            }
        }
        .padding(.horizontal)
        .frame(width: 360,height: 70)
        .padding(8)
        .background(Color.theme.foreground)
    }
    
    private func getOneDayChange() -> Double {
        return account.value.currentValue - account.value.previousValue
    }
    
    private func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.value.previousValue, currentBalance: account.value.currentValue)
    }
    
    private func getTotalChange() -> Double {
        return account.value.currentValue - account.value.invested
    }
    
    private func getTotalPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: account.value.invested, currentBalance: account.value.currentValue)
    }
}
