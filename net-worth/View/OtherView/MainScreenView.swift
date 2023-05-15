//
//  MainScreenView.swift
//  networth
//
//  Created by Kalpesh Panchbhai on 07/11/22.
//

import SwiftUI

struct MainScreenView: View {
    
    @State public var tabSelection: MainScreenTabBarItem = .account
    @Environment(\.scenePhase) private var scenePhase
    @State private var scenePhaseBlur = 0
    
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject private var watchViewModel = WatchViewModel()
    @StateObject private var incomeViewModel = IncomeViewModel()
    
    @StateObject var networkMonitor = NetworkMonitor()
    @State var networkUnavailable = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                MainScreenTabBarContainerView(accountViewModel: accountViewModel, incomeViewModel : incomeViewModel, watchViewModel: watchViewModel, selection: $tabSelection, content: {
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
                .alert("Network is unavailable. You can continue to use it, it will sync automatically once the network is available.", isPresented: $networkUnavailable) {
                    Button("OK", role: .cancel) { }
                }
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
            networkUnavailable = !networkMonitor.isConnected
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
