//
//  TabBarItemsPreferenceKey.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/05/23.
//

import Foundation
import SwiftUI

struct MainScreenTabBarItemsPreferenceKey: PreferenceKey {
    
    static var defaultValue: [MainScreenTabBarItem] = []
    
    static func reduce(value: inout [MainScreenTabBarItem], nextValue: () -> [MainScreenTabBarItem]) {
        value += nextValue()
    }
}

struct TabBarItemViewModifier: ViewModifier {
    
    let tab: MainScreenTabBarItem
    @Binding var selection: MainScreenTabBarItem
    func body(content: Content) -> some View {
        content
            .opacity(selection == tab ? 1.0 : 0.0)
            .preference(key: MainScreenTabBarItemsPreferenceKey.self, value: [tab])
    }
}

extension View {
    
    func tabBarItem(tab: MainScreenTabBarItem, selection: Binding<MainScreenTabBarItem>) -> some View {
        modifier(TabBarItemViewModifier(tab: tab, selection: selection))
    }
    
}
