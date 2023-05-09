//
//  MainScreenView.swift
//  networth
//
//  Created by Kalpesh Panchbhai on 07/11/22.
//

import SwiftUI

struct MainScreenView: View {
    
    @State public var tabViewSelection = 0
    
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject private var watchViewModel = WatchViewModel()
    @StateObject private var incomeViewModel = IncomeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $tabViewSelection) {
                    AccountCardList(accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                        .tabItem{
                            if(tabViewSelection==0) {
                                Image(systemName: "star.circle.fill")
                            } else {
                                Image(systemName: "star.circle")
                                    .environment(\.symbolVariants, .none)
                            }
                            Text("Accounts")
                        }.tag(0)
                        .badge(accountViewModel.accountList.count)
                    WatchListView(watchViewModel: watchViewModel)
                        .tabItem {
                            if(tabViewSelection==1) {
                                Image(systemName: "list.bullet.circle.fill")
                            } else {
                                Image(systemName: "list.bullet.circle")
                                    .environment(\.symbolVariants, .none)
                            }
                            Text("Watch Lists")
                        }.tag(1)
                        .badge(watchViewModel.watchList.count)
                    IncomeView(incomeViewModel: incomeViewModel)
                        .tabItem{
                            if(tabViewSelection==2) {
                                Image(systemName: "indianrupeesign.circle.fill")
                            } else {
                                Image(systemName: "indianrupeesign.circle")
                                    .environment(\.symbolVariants, .none)
                            }
                            Text("Incomes")
                        }.tag(2)
                        .badge(incomeViewModel.incomeList.count)
                    PieChartView(
                        values: [1500, 500, 300],
                        names: ["Rent", "Transport", "Education"],
                        formatter: {value in String(format: "$%.2f", value)})
                    .tabItem {
                        if(tabViewSelection == 3) {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        } else {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                                .environment(\.symbolVariants, .none)
                        }
                        Text("Charts")
                    }.tag(3)
                    SettingsView()
                        .tabItem{
                            if(tabViewSelection==4) {
                                Image(systemName: "gearshape.fill")
                            } else {
                                Image(systemName: "gearshape")
                                    .environment(\.symbolVariants, .none)
                            }
                            Text("Settings")
                        }.tag(4)
                }
                .onAppear {
                    Task.init {
                        await accountViewModel.getAccountList()
                        await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
                        
                        await watchViewModel.getAllWatchList()
                        
                        await incomeViewModel.getTotalBalance()
                        await incomeViewModel.getIncomeList()
                        await incomeViewModel.getIncomeTypeList()
                        await incomeViewModel.getIncomeTagList()
                        await incomeViewModel.getIncomeYearList()
                        await incomeViewModel.getIncomeFinancialYearList()
                    }
                }
            }
        }
    }
    
}
