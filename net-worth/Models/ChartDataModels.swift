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
    case other = "other"
}

enum OtherChartType: String, CaseIterable {
    case income = "income"
    case savedPercentage = "saved_percentage"
    
    var displayName: String {
        switch self {
        case .income: return "Income"
        case .savedPercentage: return "%Saved"
        }
    }
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
