//
//  TabBarItemsPreferenceKey.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/05/23.
//

import Foundation
import SwiftUI

struct TabBarItemsPreferenceKey: PreferenceKey {
    
    static var defaultValue: [TabBarItem] = []
    
    static func reduce(value: inout [TabBarItem], nextValue: () -> [TabBarItem]) {
        value += nextValue()
    }
}

struct TabBarItemViewModifier: ViewModifier {
    
    let tab: TabBarItem
    @Binding var selection: TabBarItem
    let count: Int
    func body(content: Content) -> some View {
        content
            .opacity(selection == tab ? 1.0 : 0.0)
            .preference(key: TabBarItemsPreferenceKey.self, value: [tab])
            .badge(count)
    }
}

extension View {
    
    func tabBarItem(tab: TabBarItem, selection: Binding<TabBarItem>,count : Int) -> some View {
        modifier(TabBarItemViewModifier(tab: tab, selection: selection, count: count))
    }
    
}
