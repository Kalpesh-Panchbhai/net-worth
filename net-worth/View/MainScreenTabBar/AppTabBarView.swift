//
//  MainScreenView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/11/22.
//

import SwiftUI

struct AppTabBarView: View {
    
    @State private var selection: String = "home"
    
    @State private var tabSelection: TabBarItem = .account
    
    var body: some View {
        CustomTabBarContainerView(selection: $tabSelection) {
            AccountView()
                .tabBarItem(tab: .account, selection: $tabSelection)
            
            NavigationView(){
                Text("Tab 2")
                    .navigationTitle("Income")
            }
            .tabBarItem(tab: .income, selection: $tabSelection)
            
            NavigationView(){
                Text("Tab 3")
                    .navigationTitle("Settings")
            }
            .tabBarItem(tab: .setting, selection: $tabSelection)
            
        }
    }
}

struct AppTabBarView_Previews: PreviewProvider {
    
    static var previews: some View {
        AppTabBarView()
    }
}

//extension AppTabBarView {
//
//    private var defaultTabView: some View {
//        TabView(selection: $selection) {
//            Color.red
//                .tabItem{
//                    Image(systemName: "house")
//                    Text("Home")
//                }
//            Color.blue
//                .tabItem{
//                    Image(systemName: "heart")
//                    Text("Favorites")
//                }
//            Color.orange
//                .tabItem{
//                    Image(systemName: "person")
//                    Text("Profile")
//                }
//        }
//    }
//}
