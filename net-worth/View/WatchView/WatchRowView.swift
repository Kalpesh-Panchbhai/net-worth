//
//  WatchRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 20/07/23.
//

import SwiftUI

struct WatchViewRow: View {
    
    var watch: WatchRestModel
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(watch.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ColorTheme().primaryText)
                    }
                    
                    HStack {
                        Text("1D Change: ")
                            .font(.system(size: 12))
                            .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                        
                        Text(SettingsController().getDefaultCurrency().symbol + getOneDayChange().abbreviated())
                            .font(.system(size: 14))
                            .foregroundColor(ColorTheme().primaryText)
                                
                        if(getOneDayChange() > 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.green.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowUpImageName)
                                    .foregroundColor(Color.theme.green)
                                    .font(.system(size: 12))
                            }
                            
                            Text(getOneDayPercentageChange())
                                .font(.system(size: 12))
                                .foregroundColor(ColorTheme().green)
                        } else if(getOneDayChange() < 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.red.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowDownImageName)
                                    .foregroundColor(Color.theme.red)
                                    .font(.system(size: 12))
                            }
                            
                            Text(getOneDayPercentageChange())
                                .font(.system(size: 12))
                                .foregroundColor(ColorTheme().red)
                        }
                    }
                }
            }
                    
            HStack {
                VStack(alignment: .leading) {
                    Text("Invested")
                        .font(.system(size: 12))
                        .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                    Text(SettingsController().getDefaultCurrency().symbol + watch.value.invested.abbreviated())
                        .font(.system(size: 14))
                        .foregroundColor(ColorTheme().primaryText)
                }
                        
                Spacer()
                        
                VStack(alignment: .leading) {
                    Text("Current Value")
                        .font(.system(size: 12))
                        .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                    Text(SettingsController().getDefaultCurrency().symbol + watch.value.currentValue.abbreviated())
                        .font(.system(size: 14))
                        .foregroundColor(ColorTheme().primaryText)
                }
                        
                Spacer()
                    
                VStack(alignment: .leading) {
                    Text("Gain/Loss")
                        .font(.system(size: 12))
                        .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                    HStack(spacing: 4) {
                            Text(SettingsController().getDefaultCurrency().symbol + getTotalChange().abbreviated())
                            .font(.system(size: 14))
                            .foregroundColor(ColorTheme().primaryText)
                        if(getTotalChange() > 0) {
                            Text(getTotalPercentageChange())
                                .font(.system(size: 12))
                                .foregroundColor(ColorTheme().green)
                        } else if(getTotalChange() < 0) {
                            Text(getTotalPercentageChange())
                                .font(.system(size: 12))
                                .foregroundColor(ColorTheme().red)
                        }
                    }
                }
            }
        }
    }
    
    private func getOneDayChange() -> Double {
        return watch.value.currentValue - watch.value.previousValue
    }
    
    private func getOneDayPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: watch.value.previousValue, currentBalance: watch.value.currentValue)
    }
    
    private func getTotalChange() -> Double {
        return watch.value.currentValue - watch.value.invested
    }
    
    private func getTotalPercentageChange() -> String {
        return CommonController.getGrowthPercentage(previousBalance: watch.value.invested, currentBalance: watch.value.currentValue)
    }
}
