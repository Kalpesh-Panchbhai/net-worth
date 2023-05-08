//
//  MainScreenView.swift
//  networth
//
//  Created by Kalpesh Panchbhai on 07/11/22.
//

import SwiftUI

struct MainScreenView: View {
    
    @State public var tabViewSelection = 0
    
    @ObservedObject private var accountViewModel = AccountViewModel()
    @ObservedObject private var watchViewModel = WatchViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $tabViewSelection) {
                    AccountCardList()
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
                    WatchListView()
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
                    IncomeView()
                        .tabItem{
                            if(tabViewSelection==2) {
                                Image(systemName: "indianrupeesign.circle.fill")
                            } else {
                                Image(systemName: "indianrupeesign.circle")
                                    .environment(\.symbolVariants, .none)
                            }
                            Text("Incomes")
                        }.tag(2)
                    SettingsView()
                        .tabItem{
                            if(tabViewSelection==3) {
                                Image(systemName: "gearshape.fill")
                            } else {
                                Image(systemName: "gearshape")
                                    .environment(\.symbolVariants, .none)
                            }
                            Text("Settings")
                        }.tag(3)
                }
                .onAppear {
                    Task.init {
                        await accountViewModel.getAccountList()
                        await watchViewModel.getAllWatchList()
                    }
                }
            }
        }
    }
    
}
