//
//  CustomTabBarContainerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/05/23.
//

import SwiftUI

struct MainScreenTabBarContainerView<Content:View>: View {
    
    @Binding var selection: MainScreenTabBarItem
    let content: Content
    @State private var tabs: [MainScreenTabBarItem] = []
    
    init(selection: Binding<MainScreenTabBarItem>, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .ignoresSafeArea()
            MainScreenTabBarView(tabs: tabs, selection: $selection, localSelection: selection)
        }
        .onPreferenceChange(MainScreenTabBarItemsPreferenceKey.self) { value in
            self.tabs = value
        }
    }
}
