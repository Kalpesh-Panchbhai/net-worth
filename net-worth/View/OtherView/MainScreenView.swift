//
//  MainScreenView.swift
//  networth
//
//  Created by Kalpesh Panchbhai on 07/11/22.
//

import SwiftUI

struct MainScreenView: View {
    
    @State var tabSelection: MainScreenTabBarItem = .account
    @State var scenePhaseBlur = 0
    @State var networkUnavailable = true
    
    @StateObject var accountViewModel = AccountViewModel()
    @StateObject var watchViewModel = WatchViewModel()
    @StateObject var incomeViewModel = IncomeViewModel()
    @StateObject var networkMonitor = NetworkMonitor()
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        NavigationStack {
            // MARK: Tab View
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
                    SettingsView(isAuthenticationRequired: SettingsController().isAuthenticationRequired(), currenySelected: SettingsController().getDefaultCurrency(), incomeViewModel: incomeViewModel)
                        .tabBarItem(tab: .setting, selection: $tabSelection)
                })
                // MARK: Network unavailable message
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
