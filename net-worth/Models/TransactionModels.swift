import Foundation

struct AccountTransaction: Codable, Identifiable, Hashable {
    let id: Int
    let accountId: Int
    let accountBrokerId: Int
    let transactionDate: String // Backend IST string: "yyyy-MM-dd HH:mm:ss"
    let value: Double
    let operation: String?
}
