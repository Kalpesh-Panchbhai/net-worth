import SwiftUI

// Navigation tabs
enum AppTab: String, CaseIterable, Identifiable {
    case home, accounts, watchlist, income, settings
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Home"
        case .accounts: return "Accounts"
        case .watchlist: return "Watchlists"
        case .income: return "Incomes"
        case .settings: return "Settings"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"
        case .accounts: return "creditcard"
        case .watchlist: return "heart"
        case .income: return "indianrupeesign.circle"
        case .settings: return "gearshape"
        }
    }
}
