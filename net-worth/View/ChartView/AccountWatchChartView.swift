//
//  ChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/05/23.
//

import SwiftUI
import Charts

struct AccountWatchChartView: View {
    
    var accountList: [Account]
    
    @State var scenePhaseBlur = 0
    @State var range = ConstantUtils.oneMonthRange
    
    @StateObject var chartViewModel = ChartViewModel()
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var financeViewModel = FinanceViewModel()
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
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
                                    let accountBrokerList = await accountViewModel.getAccountTransactionListForAllAccountsWithRange(accountList: accountList, range: range)
                                    if(!range.elementsEqual("All")) {
                                        await accountViewModel.getAccountTransactionListForAllAccountsBelowRange(accountList: accountList, range: range)
                                    }
                                    await financeViewModel.getMultipleSymbolDetail(brokerAccountList: accountBrokerList, range: range)
                                    await chartViewModel.getChartDataForAllAccounts(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
                                }
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .listRowBackground(Color.theme.foreground)
                        }
                        .background(Color.theme.background)
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
                            let accountBrokerList = await accountViewModel.getAccountTransactionListForAllAccountsWithRange(accountList: accountList, range: range)
                            if(!range.elementsEqual("All")) {
                                await accountViewModel.getAccountTransactionListForAllAccountsBelowRange(accountList: accountList, range: range)
                            }
                            await financeViewModel.getMultipleSymbolDetail(brokerAccountList: accountBrokerList, range: range)
                            await chartViewModel.getChartDataForAllAccounts(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
                        }
                    }
                    .navigationTitle("Chart")
                    .navigationBarTitleDisplayMode(.inline)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
    
    private func getCAGRPercentage() -> String {
        return CommonController.CalculateCAGR(firstBalance: chartViewModel.chartDataList.first?.value ?? 0.0, lastBalance: chartViewModel.chartDataList.last?.value ?? 0.0, days: (chartViewModel.chartDataList.first!.date.distance(to: chartViewModel.chartDataList.last!.date) + 86400)/86400)
    }
}
