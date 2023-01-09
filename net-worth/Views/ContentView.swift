//
//  ContentView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 07/01/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CardsScreen()
                .tabItem{
                    Image(systemName: "star.fill")
                    Text("Accounts")
                }.tag("account_view")
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
