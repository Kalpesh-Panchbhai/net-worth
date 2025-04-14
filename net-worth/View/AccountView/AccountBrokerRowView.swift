//
//  AccountBrokerRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountBrokerRowView: View {
    
    var account: AccountInBrokerRestModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme().primaryText)
                            
                    HStack {
                        Text("1D Change: " + SettingsController().getDefaultCurrency().symbol + getOneDayChange().abbreviated())
                            .font(.subheadline)
                            .foregroundColor(ColorTheme().secondaryText)
                                
                        if(getOneDayChange() > 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.green.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowUpImageName)
                                    .foregroundColor(Color.theme.green)
                                    .font(.caption.bold())
                            }
                            
                            Text(getOneDayPercentageChange())
                                .font(.caption)
                                .foregroundColor(ColorTheme().green)
                        } else if(getOneDayChange() < 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.red.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowDownImageName)
                                    .foregroundColor(Color.theme.red)
                                    .font(.caption.bold())
                            }
                            
                            Text(getOneDayPercentageChange())
                                .font(.caption)
                                .foregroundColor(ColorTheme().red)
                        }
                    }
                }
            }
                    
            HStack {
                VStack(alignment: .leading) {
                    Text("Invested")
                        .font(.caption)
                        .foregroundColor(ColorTheme().secondaryText)
                    Text(SettingsController().getDefaultCurrency().symbol + account.value.invested.abbreviated())
                        .foregroundColor(ColorTheme().primaryText)
                }
                        
                Spacer()
                        
                VStack(alignment: .leading) {
                    Text("Current Value")
                        .font(.caption)
                        .foregroundColor(ColorTheme().secondaryText)
                    Text(SettingsController().getDefaultCurrency().symbol + account.value.currentValue.abbreviated())
                        .foregroundColor(ColorTheme().primaryText)
                }
                        
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Total Units")
                        .font(.caption)
                        .foregroundColor(ColorTheme().secondaryText)
                    Text(account.currentUnit.abbreviated())
                        .foregroundColor(ColorTheme().primaryText)
                }
                        
                Spacer()
                        
                VStack(alignment: .leading) {
                    Text("Gain/Loss")
                        .font(.caption)
                        .foregroundColor(ColorTheme().secondaryText)
                    HStack(spacing: 4) {
                        Text(SettingsController().getDefaultCurrency().symbol + getTotalChange().abbreviated())
                            .foregroundColor(ColorTheme().primaryText)
                        if(getTotalChange() > 0) {
                            Text(getTotalPercentageChange())
                                .font(.caption)
                                .foregroundColor(ColorTheme().green)
                        } else if(getTotalChange() < 0) {
                            Text(getTotalPercentageChange())
                                .font(.caption)
                                .foregroundColor(ColorTheme().red)
                        }
                    }
                }
            }
        }
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
