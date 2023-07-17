//
//  MainScreenView.swift
//  networth
//
//  Created by Kalpesh Panchbhai on 07/11/22.
//

import SwiftUI

struct MainScreenView: View {

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
                TabView {
                    AccountCardList(accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                        .tabItem {
                            Label("Accounts", systemImage: "star.circle")
                        }
                        .badge(accountViewModel.accountList.count)
                    
                    WatchView(watchViewModel: watchViewModel)
                        .tabItem {
                            Label("Watch Lists", systemImage: "bookmark")
                        }
                        .badge(watchViewModel.watchList.count)
                    
                    IncomeView(incomeViewModel: incomeViewModel)
                        .tabItem {
                            Label("Incomes", systemImage: "indianrupeesign.circle")
                        }
                        .badge(incomeViewModel.incomeList.count)
                    
                    ChartView(watchViewModel: watchViewModel, accountViewModel: accountViewModel)
                        .tabItem {
                            Label("Charts", systemImage: "chart.line.uptrend.xyaxis.circle")
                        }
                    
                    SettingsView(isAuthenticationRequired: SettingsController().isAuthenticationRequired(), currenySelected: SettingsController().getDefaultCurrency(), incomeViewModel: incomeViewModel)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
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
                await incomeViewModel.getTotalTaxPaid()
                await incomeViewModel.getIncomeList()
                await incomeViewModel.getIncomeTypeList()
                await incomeViewModel.getIncomeTagList()
                await incomeViewModel.getIncomeYearList()
                await incomeViewModel.getIncomeFinancialYearList()
            }
        }
    }
}
