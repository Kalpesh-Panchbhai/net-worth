//
//  AccountBrokerChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/12/23.
//

import SwiftUI

struct AccountBrokerChartView: View {
    
    var brokerID: String
    var accountID: String
    var symbol: String
    
    @State var range = ConstantUtils.oneMonthRange
    
    @StateObject var chartViewModel = ChartViewModel()
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var financeViewModel = FinanceViewModel()
    
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
                            if(accountID.isEmpty) {
                                await chartViewModel.getChartData(id: brokerID, range: range)
                            } else {
                                await chartViewModel.getChartData(id: accountID, range: range)
                            }
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
                if(accountID.isEmpty) {
                    await chartViewModel.getChartData(id: brokerID, range: range)
                } else {
                    await chartViewModel.getChartData(id: accountID, range: range)
                }
            }
        }
    }
    
    private func getCAGRPercentage() -> String {
        return CommonController.CalculateCAGR(firstBalance: chartViewModel.chartDataList.first?.value ?? 0.0, lastBalance: chartViewModel.chartDataList.last?.value ?? 0.0, days: (chartViewModel.chartDataList.first!.date.distance(to: chartViewModel.chartDataList.last!.date) + 86400)/86400)
    }
}
