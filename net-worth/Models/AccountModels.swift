import Foundation

struct Account: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let type: String
    let isActive: Bool
    let needsDailyData: Bool
    let currency: String
}

struct AccountValue: Codable, Hashable {
    let currentValue: Double
    let previousValue: Double
    let invested: Double
}

struct AccountSummary: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let type: String
    let isActive: Bool
    let currency: String
    let currentDayValue: Double
    let previousDayValue: Double
    let invested: Double
}

// MARK: - Request Models
struct CreateAccountRequest: Codable {
    let userId: Int
    let name: String
    let type: String
    let currency: String
    let isActive: Bool?
    let needsDailyData: Bool?
}

struct UpdateAccountRequest: Codable {
    let name: String?
    let isActive: Bool?
}

// MARK: - API Response Wrappers
struct ApiResponseAccount: Codable {
    let success: Bool
    let data: Account
}

struct ApiResponseAccountSummaryList: Codable {
    let success: Bool
    let data: [AccountSummary]
}
