//
//  CustomTabBarView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/05/23.
//

import SwiftUI

struct MainScreenTabBarView: View {
    
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var incomeViewModel : IncomeViewModel
    @ObservedObject var watchViewModel: WatchViewModel
    
    let tabs: [MainScreenTabBarItem]
    @Binding var selection: MainScreenTabBarItem
    @Namespace private var namespace
    @State var localSelection: MainScreenTabBarItem
    var body: some View {
        tabBar
            .onChange(of: selection, perform: { value in
                withAnimation(.easeInOut) {
                    localSelection = value
                }
            })
    }
}

extension MainScreenTabBarView {
    
    private var tabBar: some View {
        HStack {
            ForEach(tabs, id: \.self) { tab in
                tabView(tab: tab)
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
    
    private func tabView(tab: MainScreenTabBarItem) -> some View {
        VStack {
            if(tab == .account) {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.lightBlue)
                            .frame(height: 20)
                        Text("\(accountViewModel.accountList.count)")
                            .font(.system(size: 10))
                            .bold()
                    }
                }
            } else if (tab == .watchlist) {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.lightBlue)
                            .frame(height: 20)
                        Text("\(watchViewModel.watchList.count)")
                            .font(.system(size: 10))
                            .bold()
                    }
                }
            } else if (tab == .income) {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.lightBlue)
                            .frame(height: 20)
                        Text("\(incomeViewModel.incomeList.count)")
                            .font(.system(size: 10))
                            .bold()
                    }
                }
            }
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
    
    private func switchToTab(tab: MainScreenTabBarItem) {
        selection = tab
    }
}
