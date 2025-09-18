import Foundation

struct IncomeSource: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let isDefault: Bool
}

// MARK: - Reusable Named Entity protocol
protocol NamedEntity: Identifiable, Hashable, Codable {
    var id: Int { get }
    var userId: Int { get }
    var name: String { get }
    var isDefault: Bool { get }
}

extension IncomeSource: NamedEntity {}

struct IncomeTag: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let name: String
    let isDefault: Bool
}

extension IncomeTag: NamedEntity {}

struct Income: Codable, Identifiable, Hashable {
    let id: Int
    let userId: Int
    let incomeSourceId: Int
    let incomeTagId: Int
    let netAmount: Double
    let taxPaid: Double
    let currency: String
    let creditedDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId, incomeSourceId, incomeTagId, netAmount, taxPaid, currency, creditedDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        incomeSourceId = try container.decode(Int.self, forKey: .incomeSourceId)
        incomeTagId = try container.decode(Int.self, forKey: .incomeTagId)
        
        // Accept Int or Double for amounts
        if let amt = try? container.decode(Double.self, forKey: .netAmount) {
            netAmount = amt
        } else if let amtInt = try? container.decode(Int.self, forKey: .netAmount) {
            netAmount = Double(amtInt)
        } else {
            netAmount = 0
        }
        
        if let tax = try? container.decode(Double.self, forKey: .taxPaid) {
            taxPaid = tax
        } else if let taxInt = try? container.decode(Int.self, forKey: .taxPaid) {
            taxPaid = Double(taxInt)
        } else {
            taxPaid = 0
        }
        
        let dateString = try container.decode(String.self, forKey: .creditedDate)
        // Parse backend date string (YYYY-MM-DD format) into a Date
        guard let parsed = DateFormatter.incomeBackend.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .creditedDate, in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        creditedDate = parsed
        currency = try container.decode(String.self, forKey: .currency)
    }

    // Convenience initializer
    init(id: Int, userId: Int, incomeSourceId: Int, incomeTagId: Int, netAmount: Double, taxPaid: Double, currency: String, creditedDate: Date) {
        self.id = id
        self.userId = userId
        self.incomeSourceId = incomeSourceId
        self.incomeTagId = incomeTagId
        self.netAmount = netAmount
        self.taxPaid = taxPaid
        self.currency = currency
        self.creditedDate = creditedDate
    }
}

// MARK: - Request Models
struct CreateIncomeRequest: Codable {
    let userId: Int
    let incomeSourceId: Int
    let incomeTagId: Int
    let netAmount: Double
    let taxPaid: Double?
    let currency: String
    let creditedDate: String // Date-only format (YYYY-MM-DD) as per OpenAPI spec
}

struct UpdateIncomeRequest: Codable {
    let incomeSourceId: Int?
    let incomeTagId: Int?
    let netAmount: Double?
    let taxPaid: Double?
    let currency: String?
    let creditedDate: String? // Date-only format (YYYY-MM-DD)
}

struct CreateIncomeSourceRequest: Codable {
    let userId: Int
    let name: String
    let isDefault: Bool?
}

struct CreateIncomeTagRequest: Codable {
    let userId: Int
    let name: String
    let isDefault: Bool?
}

// MARK: - API Response Models
struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
}

struct ApiResponseIncome: Codable {
    let success: Bool
    let data: Income
}

struct ApiResponseIncomeList: Codable {
    let success: Bool
    let data: [Income]
}

struct ApiResponseIncomeSource: Codable {
    let success: Bool
    let data: IncomeSource
}

struct ApiResponseIncomeSourceList: Codable {
    let success: Bool
    let data: [IncomeSource]
}

struct ApiResponseIncomeTag: Codable {
    let success: Bool
    let data: IncomeTag
}

struct ApiResponseIncomeTagList: Codable {
    let success: Bool
    let data: [IncomeTag]
}

struct ApiError: Codable {
    let code: String
    let message: String
}
