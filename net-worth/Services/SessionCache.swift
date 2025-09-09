import Foundation

// Simple in-memory cache for a single app session
final class SessionCache {
    static let shared = SessionCache()
    private init() {}

    // Basic entities
    var accountsByUser: [Int: [AccountSummary]] = [:]
    var watchlistsByUser: [Int: [WatchlistSummary]] = [:]
    var holdingsByAccount: [Int: [HoldingSummary]] = [:]

    // Chart cache: key by (entityType, id, period)
    struct ChartKey: Hashable {
        let type: ChartEntityType
        let id: Int
        let period: ChartTimePeriod
    }
    var chartData: [ChartKey: [ChartData]] = [:]
}
