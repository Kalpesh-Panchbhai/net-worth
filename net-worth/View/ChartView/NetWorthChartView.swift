//
//  NetWorthChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 30/05/23.
//

import SwiftUI
import Charts

struct NetWorthChartView: View {
    
    var accountList: [Account]
    
    @State var scenePhaseBlur = 0
    @State var range = "1M"
    
    @StateObject var chartViewModel = ChartViewModel()
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var incomeViewModel = IncomeViewModel()
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    List {
                        SingleLineLollipopChartView(chartDataList: chartViewModel.chartDataList, isPercentageChart: true)
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
                                await incomeViewModel.getIncomeList()
                                await accountViewModel.getAccountTransactionListWithRangeMultipleAccounts(accountList: accountList, range: range)
                                if(!range.elementsEqual("All")) {
                                    await accountViewModel.getAccountLastTransactionBelowRange(accountList: accountList, range: range)
                                }
                                await chartViewModel.getChartDataForAccounts(accountViewModel: accountViewModel, range: range)
                                await chartViewModel.getChartDataForNetworth(incomeViewModel: incomeViewModel)
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
                    await incomeViewModel.getIncomeList()
                    await accountViewModel.getAccountTransactionListWithRangeMultipleAccounts(accountList: accountList, range: range)
                    if(!range.elementsEqual("All")) {
                        await accountViewModel.getAccountLastTransactionBelowRange(accountList: accountList, range: range)
                    }
                    await chartViewModel.getChartDataForAccounts(accountViewModel: accountViewModel, range: range)
                    await chartViewModel.getChartDataForNetworth(incomeViewModel: incomeViewModel)
                }
            }
            .navigationTitle("Net Worth Chart")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
