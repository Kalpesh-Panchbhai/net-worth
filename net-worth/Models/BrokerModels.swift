import Foundation

struct AccountBroker: Codable, Identifiable, Hashable {
    let id: Int
    let accountId: Int
    let symbol: String
    let name: String
    let currentUnit: Double
    let value: AccountValue
}
