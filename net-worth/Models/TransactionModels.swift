import Foundation

struct AccountTransaction: Codable, Identifiable, Hashable {
    let id: Int
    let accountId: Int
    let accountBrokerId: Int
    let transactionDate: String // Backend IST string: "yyyy-MM-dd HH:mm:ss"
    let value: Double
    let invested: Double?
    let operation: String?
}

// MARK: - New Transaction Models (aligned with OpenAPI)
struct Transaction: Codable, Identifiable, Hashable {
    let id: Int
    let accountId: Int
    let holdingId: Int
    let txnDate: String // Date format: "YYYY-MM-DD"
    let invested: Double
    let value: Double
}

struct CreateTransactionRequest: Codable {
    let accountId: Int
    let holdingId: Int
    let txnDate: String // Date format: "YYYY-MM-DD"
    let invested: Double
    let value: Double
    let mode: String // "add" or "update"
}

// MARK: - API Response Wrappers
struct ApiResponseTransaction: Codable {
    let success: Bool
    let data: Transaction
}

struct ApiResponseTransactionList: Codable {
    let success: Bool
    let data: [Transaction]
}

