//
//  CustomTabBarContainerView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/05/23.
//

import SwiftUI

struct CustomTabBarContainerView<Content:View>: View {
    
    @Binding var selection: TabBarItem
    let content: Content
    @State private var tabs: [TabBarItem] = []
    
    @ObservedObject private var incomeViewModel: IncomeViewModel
    
    init(selection: Binding<TabBarItem>, @ViewBuilder content: () -> Content, incomeViewModel: IncomeViewModel) {
        self._selection = selection
        self.content = content()
        self.incomeViewModel = incomeViewModel
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .ignoresSafeArea()
            VStack {
                if(selection == .income) {
                    tabBarVersion2
                }
                CustomTabBarView(tabs: tabs, selection: $selection, localSelection: selection)
            }
        }
        .onPreferenceChange(TabBarItemsPreferenceKey.self) { value in
            self.tabs = value
        }
    }
    
    private var tabBarVersion2: some View {
        HStack {
            Text("Total: \(SettingsController().getDefaultCurrency().code) \(incomeViewModel.incomeTotalAmount.withCommas(decimalPlace: 2))")
                .foregroundColor(Color.navyBlue)
                .font(.title2)
        }
        .padding(6).frame(width: 360, height: 50)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.navyBlue.opacity(0.3),radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}
