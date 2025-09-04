import Foundation

// MARK: - Holding Models (replaces AccountBroker)
struct Holding: Codable, Identifiable, Hashable {
    let id: Int
    let accountId: Int
    let name: String
    let symbol: String
}

struct HoldingSummary: Codable, Identifiable, Hashable {
    let id: Int
    let accountId: Int
    let name: String
    let symbol: String
    let units: Double
    let currentDayValue: Double
    let previousDayValue: Double
    let invested: Double
    
    // Legacy compatibility for existing views
    var currentUnit: Double { units }
    var value: AccountValue {
        AccountValue(currentValue: currentDayValue, previousValue: previousDayValue, invested: invested)
    }
}

// MARK: - Request Models
struct CreateHoldingRequest: Codable {
    let accountId: Int
    let name: String
    let symbol: String
}

// MARK: - API Response Wrappers
struct ApiResponseHolding: Codable {
    let success: Bool
    let data: Holding
}

struct ApiResponseHoldingSummaryList: Codable {
    let success: Bool
    let data: [HoldingSummary]
}

// MARK: - Legacy Compatibility (for gradual migration)
typealias AccountBroker = HoldingSummary
