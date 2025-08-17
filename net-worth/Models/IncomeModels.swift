import Foundation

struct IncomeType: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let isDefault: Bool
}

struct IncomeTag: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let isDefault: Bool
}

struct Income: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let amount: Double
    let taxPaid: Double
    let creditedDate: Date
    let currency: String
    let incomeType: IncomeType
    let incomeTag: IncomeTag
    
    enum CodingKeys: String, CodingKey {
        case id, userId, amount, taxPaid, creditedDate, currency, incomeType, incomeTag
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        // Accept Int or Double for amounts
        if let amt = try? container.decode(Double.self, forKey: .amount) {
            amount = amt
        } else if let amtInt = try? container.decode(Int.self, forKey: .amount) {
            amount = Double(amtInt)
        } else {
            amount = 0
        }
        if let tax = try? container.decode(Double.self, forKey: .taxPaid) {
            taxPaid = tax
        } else if let taxInt = try? container.decode(Int.self, forKey: .taxPaid) {
            taxPaid = Double(taxInt)
        } else {
            taxPaid = 0
        }
        let dateString = try container.decode(String.self, forKey: .creditedDate)
        guard let parsed = DateFormatter.incomeBackend.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .creditedDate, in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        creditedDate = parsed
        currency = try container.decode(String.self, forKey: .currency)
        incomeType = try container.decode(IncomeType.self, forKey: .incomeType)
        incomeTag = try container.decode(IncomeTag.self, forKey: .incomeTag)
    }
}
