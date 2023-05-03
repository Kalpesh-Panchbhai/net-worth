//
//  ChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/05/23.
//

import SwiftUI
import Charts

struct ChartView: View {
    @StateObject var chartViewModel = ChartViewModel()
    @StateObject var accountViewModel = AccountViewModel()
    @State var range = "1M"
    
    var accountList: [Account]
    
    var body: some View {
        VStack {
            HStack {
                List {
                    Chart {
                        ForEach(chartViewModel.chartDataList, id: \.self) { item in
                            LineMark(
                                x: .value("Mount", item.date),
                                y: .value("Value", item.value)
                            )
                        }
                    }
                    .frame(height: 250)
                    
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
                            await accountViewModel.getAccountTransactionListWithRangeMultipleAccounts(accountList: accountList, range: range)
                            await chartViewModel.getChartDataForAccounts(accountViewModel: accountViewModel)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountTransactionListWithRangeMultipleAccounts(accountList: accountList, range: range)
                await chartViewModel.getChartDataForAccounts(accountViewModel: accountViewModel)
            }
        }
    }
}
