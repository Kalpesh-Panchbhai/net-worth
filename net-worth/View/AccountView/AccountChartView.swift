//
//  AccountChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 17/02/23.
//

import SwiftUI
import Charts

struct AccountChartView: View {
    
    var accountID: String
    
    @State var range = ConstantUtils.oneMonthRange
    
    @StateObject var chartViewModel = ChartViewModel()
    @StateObject var accountViewModel = AccountViewModel()
    
    var body: some View {
        VStack {
            HStack {
                List {
                    if(chartViewModel.chartDataList.count > 0) {
                        HStack {
                            Text("Yearly Growth")
                            Spacer()
                            Text(getCAGRPercentage())
                        }
                        .listRowBackground(Color.theme.foreground)
                        .foregroundColor(Color.theme.primaryText)
                    }
                    
                    SingleLineLollipopChartView(chartDataList: chartViewModel.chartDataList)
                        .listRowBackground(Color.theme.foreground)
                    
                    Picker(selection: $range, content: {
                        Text(ConstantUtils.oneMonthRange).tag(ConstantUtils.oneMonthRange)
                        Text(ConstantUtils.threeMonthRange).tag(ConstantUtils.threeMonthRange)
                        Text(ConstantUtils.sixMonthRange).tag(ConstantUtils.sixMonthRange)
                        Text(ConstantUtils.oneYearRange).tag(ConstantUtils.oneYearRange)
                        Text(ConstantUtils.twoYearRange).tag(ConstantUtils.twoYearRange)
                        Text(ConstantUtils.fiveYearRange).tag(ConstantUtils.fiveYearRange)
                    }, label: {
                        
                    })
                    .onChange(of: range) { value in
                        Task.init {
                            await accountViewModel.getAccountTransactionListWithRange(id: accountID, range: range)
                            await accountViewModel.getAccountTransactionListBelowRange(id: accountID, range: range)
                            await chartViewModel.getChartDataForOneAccountInANonBroker(accountViewModel: accountViewModel, range: range)
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .listRowBackground(Color.theme.foreground)
                }
                .background(Color.theme.background)
                .scrollContentBackground(.hidden)
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountTransactionListWithRange(id: accountID, range: range)
                await accountViewModel.getAccountTransactionListBelowRange(id: accountID, range: range)
                await chartViewModel.getChartDataForOneAccountInANonBroker(accountViewModel: accountViewModel, range: range)
            }
        }
    }
    
    private func getCAGRPercentage() -> String {
        return CommonController.CalculateCAGR(firstBalance: chartViewModel.chartDataList.first?.value ?? 0.0, lastBalance: chartViewModel.chartDataList.last?.value ?? 0.0, days: (chartViewModel.chartDataList.first!.date.distance(to: chartViewModel.chartDataList.last!.date) + 86400)/86400)
    }
}
