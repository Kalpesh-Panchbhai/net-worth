//
//  ChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/05/23.
//

import SwiftUI
import Charts

struct AccountWatchListChartView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var scenePhaseBlur = 0
    
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
                            if(!range.elementsEqual("All")) {
                                await accountViewModel.getAccountLastTransactionBelowRange(accountList: accountList, range: range)
                            }
                            await chartViewModel.getChartDataForAccounts(accountViewModel: accountViewModel, range: range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .background(Color.navyBlue)
                .scrollContentBackground(.hidden)
            }
        }
        .blur(radius: CGFloat(scenePhaseBlur))
        .onChange(of: scenePhase, perform: { value in
            if(value == .active) {
                scenePhaseBlur = 0
            } else {
                scenePhaseBlur = 5
            }
        })
        .onAppear {
            Task.init {
                await accountViewModel.getAccountTransactionListWithRangeMultipleAccounts(accountList: accountList, range: range)
                if(!range.elementsEqual("All")) {
                    await accountViewModel.getAccountLastTransactionBelowRange(accountList: accountList, range: range)
                }
                await chartViewModel.getChartDataForAccounts(accountViewModel: accountViewModel, range: range)
            }
        }
    }
}
