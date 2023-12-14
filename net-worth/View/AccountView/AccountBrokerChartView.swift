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
    
    @State var range = "1M"
    
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
                        Text("1M").tag("1M")
                        Text("3M").tag("3M")
                        Text("6M").tag("6M")
                        Text("1Y").tag("1Y")
                        Text("2Y").tag("2Y")
                        Text("5Y").tag("5Y")
                    }, label: {
                        
                    })
                    .onChange(of: range) { value in
                        Task.init {
                            if(accountID.isEmpty) {
                                let accountList = await accountViewModel.getAccountTransactionsOfAllAccountsInBroker(brokerID: brokerID, range: range)
                                await financeViewModel.getMultipleSymbolDetail(brokerAccountList: accountList, range: range)
                                await chartViewModel.getChartDataForAllAccountsInABroker(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
                            } else {
                                await accountViewModel.getAccountTransactionsInBrokerAccountList(brokerID: brokerID, accountID: accountID, range: range)
                                await financeViewModel.getSymbolDetail(symbol: symbol, range: range)
                                await chartViewModel.getChartDataForOneAccountInABroker(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
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
                    let accountList = await accountViewModel.getAccountTransactionsOfAllAccountsInBroker(brokerID: brokerID, range: range)
                    await financeViewModel.getMultipleSymbolDetail(brokerAccountList: accountList, range: range)
                    await chartViewModel.getChartDataForAllAccountsInABroker(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
                } else {
                    await accountViewModel.getAccountTransactionsInBrokerAccountList(brokerID: brokerID, accountID: accountID, range: range)
                    await financeViewModel.getSymbolDetail(symbol: symbol, range: range)
                    await chartViewModel.getChartDataForOneAccountInABroker(accountViewModel: accountViewModel, financeViewModel: financeViewModel, range: range)
                }
            }
        }
    }
    
    private func getCAGRPercentage() -> String {
        return CommonController.CalculateCAGR(firstBalance: chartViewModel.chartDataList.first?.value ?? 0.0, lastBalance: chartViewModel.chartDataList.last?.value ?? 0.0, days: (chartViewModel.chartDataList.first!.date.distance(to: chartViewModel.chartDataList.last!.date) + 86400)/86400)
    }
}
