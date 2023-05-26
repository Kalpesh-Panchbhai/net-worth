//
//  CustomTabBarContainerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/05/23.
//

import SwiftUI

struct MainScreenTabBarContainerView<Content:View>: View {
    
    let content: Content
    
    @Binding var selection: MainScreenTabBarItem
    @State var tabs: [MainScreenTabBarItem] = []
    
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var incomeViewModel : IncomeViewModel
    @ObservedObject var watchViewModel: WatchViewModel
    
    init(accountViewModel: AccountViewModel, incomeViewModel : IncomeViewModel, watchViewModel: WatchViewModel, selection: Binding<MainScreenTabBarItem>, @ViewBuilder content: () -> Content) {
        self.accountViewModel = accountViewModel
        self.incomeViewModel = incomeViewModel
        self.watchViewModel = watchViewModel
        self._selection = selection
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .ignoresSafeArea()
            MainScreenTabBarView(accountViewModel: accountViewModel, incomeViewModel: incomeViewModel, watchViewModel: watchViewModel, tabs: tabs, selection: $selection, localSelection: selection)
        }
        .onPreferenceChange(MainScreenTabBarItemsPreferenceKey.self) { value in
            self.tabs = value
        }
    }
}
