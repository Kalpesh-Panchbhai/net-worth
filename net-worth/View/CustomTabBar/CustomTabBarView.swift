//
//  CustomTabBarView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/05/23.
//

import SwiftUI

struct CustomTabBarView: View {
    
    let tabs: [TabBarItem]
    @Binding var selection: TabBarItem
    @Namespace private var namespace
    @State var localSelection: TabBarItem
    var body: some View {
        tabBarVersion2
            .onChange(of: selection, perform: { value in
                withAnimation(.easeInOut) {
                    localSelection = value
                }
            })
    }
}

extension CustomTabBarView {
    
    private var tabBarVersion2: some View {
        HStack {
            ForEach(tabs, id: \.self) { tab in
                tabView2(tab: tab)
                    .onTapGesture {
                        switchToTab(tab: tab)
                    }
            }
        }
        .padding(3)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .cornerRadius(10)
        .shadow(color: Color.navyBlue.opacity(0.3),radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    private func tabView2(tab: TabBarItem) -> some View {
        VStack {
            Image(systemName: localSelection == tab ? tab.iconNameFill : tab.iconName)
                .font(.system(size: 20))
            Text(tab.title)
                .bold(localSelection == tab)
                .font(.system(size: 10))
        }
        .foregroundColor(tab.color)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if localSelection == tab {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.lightBlue.opacity(0.2))
                        .matchedGeometryEffect(id: "background_rectangle", in: namespace)
                }
            }
        )
    }
    
    private func switchToTab(tab: TabBarItem) {
        selection = tab
    }
}
