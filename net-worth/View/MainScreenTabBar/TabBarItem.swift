//
//  TabBarItem.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 11/11/22.
//

import Foundation
import SwiftUI

enum TabBarItem: Hashable {
    case account, income, setting
    
    var iconName: String {
        switch self {
        case .account: return "star.fill"
        case .income: return "indianrupeesign.circle.fill"
        case .setting: return "slider.horizontal.3"
        }
    }
    
    var title: String {
        switch self {
        case .account: return "Accounts"
        case .income: return "Income"
        case .setting: return "Settings"
        }
    }
    
    var color: Color {
        switch self {
        case .account: return Color.red
        case .income: return Color.blue
        case .setting: return Color.green
        }
    }
}
