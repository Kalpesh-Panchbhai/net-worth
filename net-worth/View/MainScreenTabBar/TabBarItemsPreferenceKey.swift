//
//  TabBarItemsPreferenceKey.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/11/22.
//

import Foundation
import SwiftUI

struct tabBarItemsPreferenceKey: PreferenceKey {
    
    static var defaultValue: [TabBarItem] = []
    
    static func reduce(value: inout [TabBarItem], nextValue: () -> [TabBarItem]) {
        value += nextValue()
    }
}

struct TabBarItemViewModifier: ViewModifier {
    
    let tab: TabBarItem
    
    @Binding var selection: TabBarItem
    
    func body(content: Content) -> some View {
        content
            .opacity(selection == tab ? 1.0 : 0.0)
            .preference(key: tabBarItemsPreferenceKey.self, value: [tab])
    }
}

extension View {
    
    func tabBarItem(tab: TabBarItem, selection: Binding<TabBarItem>) -> some View {
        modifier(TabBarItemViewModifier(tab: tab, selection: selection))
    }
}
