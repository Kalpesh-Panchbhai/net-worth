import Foundation

struct Watchlist: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let totalAccount: Int
    let value: WatchlistValue
}

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
