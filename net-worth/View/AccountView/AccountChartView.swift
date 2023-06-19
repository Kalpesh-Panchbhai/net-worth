//
//  AccountChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 17/02/23.
//

import SwiftUI
import Charts

struct AccountChartView: View {
    
    var account: Account
    
    @State var range = "1M"
    
    @StateObject var chartViewModel = ChartViewModel()
    @StateObject var accountViewModel = AccountViewModel()
    
    var body: some View {
        VStack {
            HStack {
                List {
                    if(chartViewModel.chartDataList.count > 0) {
                        HStack {
                            Text("Growth Rate")
                            Spacer()
                            Text(getGrowthPercentage())
                        }
                        .listRowBackground(Color.theme.foreground)
                        .foregroundColor(Color.theme.primaryText)
                    }
                    
                    SingleLineLollipopChartView(chartDataList: chartViewModel.chartDataList)
                        .listRowBackground(Color.theme.foreground)
                    
                    Picker(selection: $range, content: {
                        Text("1M").tag("1M")
                        Text("3M").tag("3M")
                        Text("6M").tag("6M")
                        Text("1Y").tag("1Y")
                        Text("2Y").tag("2Y")
                        Text("5Y").tag("5Y")
                        Text("All").tag("All")
                    }, label: {
                        
                    })
                    .onChange(of: range) { value in
                        Task.init {
                            await accountViewModel.getAccountTransactionListWithRange(id: account.id!, range: range)
                            await chartViewModel.getChartData(accountViewModel: accountViewModel)
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
                await accountViewModel.getAccountTransactionListWithRange(id: account.id!, range: range)
                await chartViewModel.getChartData(accountViewModel: accountViewModel)
            }
        }
    }
    
    private func getGrowthPercentage() -> String {
        return CommonController.getGrowthPercentage(first: chartViewModel.chartDataList.first?.value ?? 0.0, last: chartViewModel.chartDataList.last?.value ?? 0.0)
    }
}
