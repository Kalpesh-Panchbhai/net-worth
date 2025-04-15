//
//  AccountRowView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountRowView: View {
    
    var account: AccountRestModel
    var fromWatchView: Bool = false
    var isInActiveAccount: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(account.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ColorTheme().primaryText)
                        
                        if(isInActiveAccount) {
                            Text(!account.active ? "(Closed)" : "")
                                .foregroundColor(Color.theme.red)
                                .font(.caption2.italic())
                                .multilineTextAlignment(.leading)
                        }
                        if(fromWatchView) {
                            Spacer()
                            Text(account.type)
                                .foregroundColor(Color.theme.secondaryText)
                                .font(.caption.italic())
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    HStack {
                        Text("1D Change: ")
                            .font(.system(size: 14))
                            .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                        
                        Text(SettingsController().getDefaultCurrency().symbol + getOneDayChange().abbreviated())
                            .font(.system(size: 16))
                            .foregroundColor(ColorTheme().primaryText)
                                
                        if(getOneDayChange() > 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.green.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowUpImageName)
                                    .foregroundColor(Color.theme.green)
                                    .font(.system(size: 14))
                            }
                            
                            Text(getOneDayPercentageChange())
                                .font(.system(size: 14))
                                .foregroundColor(ColorTheme().green)
                        } else if(getOneDayChange() < 0) {
                            ZStack {
                                Circle()
                                    .fill(Color.theme.red.opacity(0.2))
                                    .frame(width: 17, height: 17)
                                Image(systemName: ConstantUtils.arrowDownImageName)
                                    .foregroundColor(Color.theme.red)
                                    .font(.system(size: 14))
                            }
                            
                            Text(getOneDayPercentageChange())
                                .font(.system(size: 14))
                                .foregroundColor(ColorTheme().red)
                        }
                    }
                }
            }
                    
            HStack {
                VStack(alignment: .leading) {
                    Text("Invested")
                        .font(.system(size: 14))
                        .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                    Text(SettingsController().getDefaultCurrency().symbol + account.value.invested.abbreviated())
                        .font(.system(size: 16))
                        .foregroundColor(ColorTheme().primaryText)
                }
                        
                Spacer()
                        
                VStack(alignment: .leading) {
                    Text("Current Value")
                        .font(.system(size: 14))
                        .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                    Text(SettingsController().getDefaultCurrency().symbol + account.value.currentValue.abbreviated())
                        .font(.system(size: 16))
                        .foregroundColor(ColorTheme().primaryText)
                }
                        
                if(isGainLossDataApplicable()) {
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Gain/Loss")
                            .font(.system(size: 14))
                            .foregroundColor(ColorTheme().secondaryText.opacity(0.6))
                        HStack(spacing: 4) {
                            Text(SettingsController().getDefaultCurrency().symbol + getTotalChange().abbreviated())
                                .font(.system(size: 16))
                                .foregroundColor(ColorTheme().primaryText)
                            if(getTotalChange() > 0) {
                                Text(getTotalPercentageChange())
                                    .font(.system(size: 14))
                                    .foregroundColor(ColorTheme().green)
                            } else if(getTotalChange() < 0) {
                                Text(getTotalPercentageChange())
                                    .font(.system(size: 14))
                                    .foregroundColor(ColorTheme().red)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.theme.foreground)
        .cornerRadius(10)
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
    
    private func isGainLossDataApplicable() -> Bool {
        return ((account.type.elementsEqual("Other") && getTotalChange() > 0) || account.type.elementsEqual("Broker"))
    }
}
