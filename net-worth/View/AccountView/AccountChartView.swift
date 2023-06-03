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
                    Section {
                        SingleLineLollipopChartView(chartDataList: chartViewModel.chartDataList)
                    }
                    .listRowBackground(Color.white)
                    .foregroundColor(Color.lightBlue)
                    
                    Section {
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
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .listRowBackground(Color.navyBlue)
                    .foregroundColor(Color.lightBlue)
                }
                .background(Color.navyBlue)
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
}
