import Foundation

// MARK: - User Models
struct User: Codable, Identifiable, Hashable {
    let id: Int
    let externalUserId: String
}

// MARK: - Request Models
struct CreateUserRequest: Codable {
    let externalUserId: String
}

// MARK: - API Response Wrappers
struct ApiResponseUser: Codable {
    let success: Bool
    let data: User
}
