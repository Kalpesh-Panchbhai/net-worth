//
//  AccountChartView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 01/12/23.
//

import SwiftUI

struct AccountChartView: View {
    
    var id: Any
    var type: String
    
    @State var range: String = "1M"
    @State var scenePhaseBlur = 0
    @State var chartDataList = [ChartData]()
    
    @EnvironmentObject var accountViewModel: AccountViewModel
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            HStack(alignment: .top) {
                VStack(alignment: .center) {
                    HStack {
                        SingleLineLollipopChartView(chartDataList: chartDataList, accountTransactionList: accountViewModel.accountTransactionList, showMessage: true, isAccount: isMultiLineChart())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(Color.theme.foreground)
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    Picker(selection: $range, content: {
                        Text("1M").tag("1M")
                        Text("3M").tag("3M")
                        Text("6M").tag("6M")
                        Text("1Y").tag("1Y")
                        Text("2Y").tag("2Y")
                        Text("5Y").tag("5Y")
                    }, label: {
                        Text("Account Chart Tab View")
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: range) {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        Task.init {
                            await accountViewModel.getChartDataList(id: id, type: type, range: range)
                            if(type.elementsEqual("single_broker") || type.elementsEqual("one_non_broker")) {
                                await accountViewModel.getAccountTransactionList(accountID: (id as? Int) ?? 0, type: type.elementsEqual("single_broker") ? "account_broker" : "account")
                            } else {
                                accountViewModel.accountTransactionList.removeAll()
                            }
                            filterChartData()
                        }
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
            .background(Color.theme.background)
        }
        .blur(radius: CGFloat(scenePhaseBlur))
        .onChange(of: scenePhase) { oldValue, newValue in
            if(newValue == .active) {
                scenePhaseBlur = 0
            } else {
                scenePhaseBlur = 5
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getChartDataList(id: id, type: type, range: range)
                if(type.elementsEqual("single_broker") || type.elementsEqual("one_non_broker")) {
                    await accountViewModel.getAccountTransactionList(accountID: (id as? Int) ?? 0, type: type.elementsEqual("single_broker") ? "account_broker" : "account")
                } else {
                    accountViewModel.accountTransactionList.removeAll()
                }
                filterChartData()
            }
        }
    }
    
    private func filterChartData() {
        let chartDataList = accountViewModel.chartDataList
        self.chartDataList = chartDataList.reversed().enumerated().compactMap { index, item in
            (index % getFilterIndex() == 0 || isTransactionDateChartData(item: item)) ? item : nil
        }.reversed()
    }
    
    private func getFilterIndex() -> Int {
        return Int(ceil(Double(accountViewModel.chartDataList.count) / Double(100)))
    }
    
    private func isTransactionDateChartData(item: ChartData) -> Bool {
        let accountTransactionList = accountViewModel.accountTransactionList
        return accountTransactionList.firstIndex(where: { $0.transactionDate == item.date.localToLocalStringFull() }) != nil
    }
    
    private func isMultiLineChart() -> Bool {
        return !(type.elementsEqual("one_non_broker") || type.elementsEqual("non_broker_type"))
    }

}
