import Foundation

// MARK: - Core Watchlist Models
struct Watchlist: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
}

struct WatchlistSummary: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let currentDayValue: Double
    let previousDayValue: Double
    let invested: Double
}

// MARK: - Request/Response Models
struct CreateWatchlistRequest: Codable {
    let userId: Int
    let name: String
}

struct UpdateWatchlistNameRequest: Codable {
    let name: String
}

struct CreateWatchlistAccountLinkRequest: Codable {
    let watchlistId: Int
    let accountId: Int
}

// MARK: - API Response Wrappers
struct ApiResponseWatchlist: Codable {
    let success: Bool
    let data: Watchlist
}

struct ApiResponseWatchlistSummaryList: Codable {
    let success: Bool
    let data: [WatchlistSummary]
}

// MARK: - Legacy Support (for backward compatibility)
struct WatchlistValue: Codable, Hashable {
    let currentValue: Double
    let previousValue: Double
    let invested: Double
}

// Link entity for accounts included in a watchlist
struct WatchAccount: Codable, Identifiable, Hashable {
    let id: Int
    let accountId: Int
    let watchId: Int
}

// MARK: - Extensions for backward compatibility
extension WatchlistSummary {
    var value: WatchlistValue {
        WatchlistValue(
            currentValue: currentDayValue,
            previousValue: previousDayValue,
            invested: invested
        )
    }
    
    var totalAccount: Int {
        // This would need to be calculated or provided separately
        // For now, return 0 as a placeholder
        return 0
    }
}

extension Watchlist {
    // Convert to WatchlistSummary with default values
    func toSummary(currentDayValue: Double = 0, previousDayValue: Double = 0, invested: Double = 0) -> WatchlistSummary {
        WatchlistSummary(
            id: id,
            userId: userId,
            name: name,
            currentDayValue: currentDayValue,
            previousDayValue: previousDayValue,
            invested: invested
        )
    }
}
