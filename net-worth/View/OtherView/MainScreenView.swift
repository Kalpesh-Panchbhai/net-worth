//
//  MainScreenView.swift
//  networth
//
//  Created by Kalpesh Panchbhai on 07/11/22.
//

import SwiftUI

struct MainScreenView: View {
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView() {
                    AccountCardList()
                        .tabItem{
                            Image(systemName: "star.fill")
                            Text("Accounts")
                        }.tag("account_view")
                    WatchListView()
                        .tabItem {
                            Image(systemName: "list.bullet.below.rectangle")
                            Text("Watch List")
                        }.tag("watch_view")
                    IncomeView()
                        .tabItem{
                            Image(systemName: "indianrupeesign.circle.fill")
                            Text("Income")
                        }.tag("income_view")
                    SettingsView()
                        .tabItem{
                            Image(systemName: "slider.horizontal.3")
                            Text("Settings")
                        }.tag("settings_view")
                }
            }
        }
    }
    
}

struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView()
    }
}
