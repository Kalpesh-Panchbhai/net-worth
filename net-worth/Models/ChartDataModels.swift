import Foundation

// MARK: - Chart Data Models
struct ChartData: Codable, Identifiable, Hashable {
    let id: Int
    let date: String // Date format: "YYYY-MM-DD"
    let value: Double
    let invested: Double
}

// MARK: - API Response Wrappers
struct ApiResponseChartDataList: Codable {
    let success: Bool
    let data: [ChartData]
}

// MARK: - Chart Data Request Parameters
enum ChartEntityType: String, CaseIterable {
    case holding = "holding"
    case account = "account"
    case watchlist = "watchlist"
}

enum ChartTimePeriod: String, CaseIterable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case twoYears = "2Y"
    case fiveYears = "5Y"
    case all = "ALL"
}
