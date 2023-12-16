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
    @State var range = ConstantUtils.oneMonthRange
    
    @StateObject var chartViewModel = ChartViewModel()
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var financeViewModel = FinanceViewModel()
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
                            Text(ConstantUtils.oneMonthRange).tag(ConstantUtils.oneMonthRange)
                            Text(ConstantUtils.threeMonthRange).tag(ConstantUtils.threeMonthRange)
                            Text(ConstantUtils.sixMonthRange).tag(ConstantUtils.sixMonthRange)
                            Text(ConstantUtils.oneYearRange).tag(ConstantUtils.oneYearRange)
                            Text(ConstantUtils.twoYearRange).tag(ConstantUtils.twoYearRange)
                            Text(ConstantUtils.fiveYearRange).tag(ConstantUtils.fiveYearRange)
                            Text("All").tag("All")
                        }, label: {
                            
                        })
                        .onChange(of: range) { value in
                            Task.init {
                                await incomeViewModel.getIncomeList()
                                let accountBrokerList = await accountViewModel.getAccountTransactionListForAllAccountsWithRange(accountList: accountList, range: range)
                                if(!range.elementsEqual("All")) {
                                    await accountViewModel.getAccountTransactionListForAllAccountsBelowRange(accountList: accountList, range: range)
                                }
                                await financeViewModel.getMultipleSymbolDetail(brokerAccountList: accountBrokerList, range: range)
                                await chartViewModel.getChartDataForAllAccounts(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
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
                    let accountBrokerList = await accountViewModel.getAccountTransactionListForAllAccountsWithRange(accountList: accountList, range: range)
                    if(!range.elementsEqual("All")) {
                        await accountViewModel.getAccountTransactionListForAllAccountsBelowRange(accountList: accountList, range: range)
                    }
                    await financeViewModel.getMultipleSymbolDetail(brokerAccountList: accountBrokerList, range: range)
                    await chartViewModel.getChartDataForAllAccounts(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
                    await chartViewModel.getChartDataForNetworth(incomeViewModel: incomeViewModel)
                }
            }
            .navigationTitle("Net Worth Chart")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
