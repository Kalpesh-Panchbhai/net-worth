//
//  MainScreenView.swift
//  networth
//
//  Created by Kalpesh Panchbhai on 07/11/22.
//

import SwiftUI

struct MainScreenView: View {
    
    var body: some View {
        TabView() {
            AccountView()
            .tabItem{
                Image(systemName: "star.fill")
                Text("Accounts")
            }.tag("account_view")
            NavigationView(){
                Text("Tab 2")
                    .navigationTitle("Income")
            }
            .tabItem{
                Image(systemName: "indianrupeesign.circle.fill")
                Text("Income")
            }.tag("income_view")
            NavigationView(){
                Text("Tab 3")
                    .navigationTitle("Settings")
            }
            .tabItem{
                Image(systemName: "slider.horizontal.3")
                Text("Settings")
            }.tag("settings_view")
        }
        .onAppear() {
            UITabBar.appearance().barTintColor = .darkText
            UITabBar.appearance().layer.cornerRadius = 25
            UITabBar.appearance().clipsToBounds = true
            UITabBar.appearance().layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }

}

struct MainScreenView_Previews: PreviewProvider {
    static var previews: some View {
        MainScreenView()
    }
}
