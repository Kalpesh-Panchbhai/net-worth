//
//  MainScreenView.swift
//  networth
//
//  Created by Kalpesh Panchbhai on 07/11/22.
//

import SwiftUI

struct MainScreenView: View {
    
    @State public var tabSelection: TabBarItem = .account
    
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject private var watchViewModel = WatchViewModel()
    @StateObject private var incomeViewModel = IncomeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                //                TabView(selection: $tabViewSelection) {
                //                    AccountCardList(accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                //                        .tabItem{
                //                            if(tabViewSelection==0) {
                //                                Image(systemName: "star.circle.fill")
                //                            } else {
                //                                Image(systemName: "star.circle")
                //                                    .environment(\.symbolVariants, .none)
                //                            }
                //                            Text("Accounts")
                //                        }.tag(0)
                //                        .badge(accountViewModel.accountList.count)
                //                        .toolbarBackground(
                //                                Color.navyBlue,
                //                                for: .tabBar)
                //                    WatchListView(watchViewModel: watchViewModel)
                //                        .tabItem {
                //                            if(tabViewSelection==1) {
                //                                Image(systemName: "list.bullet.circle.fill")
                //                            } else {
                //                                Image(systemName: "list.bullet.circle")
                //                                    .environment(\.symbolVariants, .none)
                //                            }
                //                            Text("Watch Lists")
                //                        }.tag(1)
                //                        .badge(watchViewModel.watchList.count)
                //                        .toolbarBackground(
                //                                Color.navyBlue,
                //                                for: .tabBar)
                //                    IncomeView(incomeViewModel: incomeViewModel)
                //                        .tabItem{
                //                            if(tabViewSelection==2) {
                //                                Image(systemName: "indianrupeesign.circle.fill")
                //                            } else {
                //                                Image(systemName: "indianrupeesign.circle")
                //                                    .environment(\.symbolVariants, .none)
                //                            }
                //                            Text("Incomes")
                //                        }.tag(2)
                //                        .badge(incomeViewModel.incomeList.count)
                //                        .toolbarBackground(
                //                                Color.navyBlue,
                //                                for: .tabBar)
                //                    ChartView(watchViewModel: watchViewModel, accountViewModel: accountViewModel)
                //                    .tabItem {
                //                        if(tabViewSelection == 3) {
                //                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                //                        } else {
                //                            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                //                                .environment(\.symbolVariants, .none)
                //                        }
                //                        Text("Charts")
                //
                //                    }.tag(3)
                //                        .toolbarBackground(
                //                                Color.navyBlue,
                //                                for: .tabBar)
                //                    SettingsView()
                //                        .tabItem{
                //                            if(tabViewSelection==4) {
                //                                Image(systemName: "gearshape.fill")
                //                            } else {
                //                                Image(systemName: "gearshape")
                //                                    .environment(\.symbolVariants, .none)
                //                            }
                //                            Text("Settings")
                //                        }.tag(4)
                //                        .toolbarBackground(
                //                                Color.navyBlue,
                //                                for: .tabBar)
                //                }
                //                .accentColor(Color.lightBlue)
                CustomTabBarContainerView(selection: $tabSelection, content: {
                    AccountCardList(accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                        .tabBarItem(tab: .account, selection: $tabSelection)
                    WatchListView(watchViewModel: watchViewModel)
                        .tabBarItem(tab: .watchlist, selection: $tabSelection)
                    IncomeView(incomeViewModel: incomeViewModel)
                        .tabBarItem(tab: .income, selection: $tabSelection)
                    ChartView(watchViewModel: watchViewModel, accountViewModel: accountViewModel)
                        .tabBarItem(tab: .chart, selection: $tabSelection)
                    SettingsView()
                        .tabBarItem(tab: .setting, selection: $tabSelection)
                })
            }
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
