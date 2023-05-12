//
//  TabBarItem.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/05/23.
//

import Foundation
import SwiftUI

enum MainScreenTabBarItem: Hashable {
case account, watchlist, income, chart, setting
    
    var iconNameFill: String {
        switch self {
        case .account: return "star.circle.fill"
        case .watchlist: return "list.bullet.circle.fill"
        case .income: return "indianrupeesign.circle.fill"
        case .chart: return "chart.line.uptrend.xyaxis.circle.fill"
        case .setting: return "gearshape.fill"
        }
    }
    
    var iconName: String {
        switch self {
        case .account: return "star.circle"
        case .watchlist: return "list.bullet.circle"
        case .income: return "indianrupeesign.circle"
        case .chart: return "chart.line.uptrend.xyaxis.circle"
        case .setting: return "gearshape"
        }
    }
    
    var title: String {
        switch self {
        case .account: return "Accounts"
        case .watchlist: return "Watch Lists"
        case .income: return "Incomes"
        case .chart: return "Charts"
        case .setting: return "Settings"
        }
    }
    
    var color: Color {
        switch self {
        case .account: return Color.navyBlue
        case .watchlist: return Color.navyBlue
        case .income: return Color.navyBlue
        case .chart: return Color.navyBlue
        case .setting: return Color.navyBlue
        }
    }
}
