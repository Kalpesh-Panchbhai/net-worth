import Foundation

struct Account: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let type: String
    let currency: String
    let active: Bool
    let value: AccountValue
}

struct AccountValue: Codable, Hashable {
    let currentValue: Double
    let previousValue: Double
    let invested: Double
}
