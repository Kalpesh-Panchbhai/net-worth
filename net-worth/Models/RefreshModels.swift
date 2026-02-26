import Foundation

struct RefreshResult: Codable {
    let message: String
    let durationMs: Int
}

struct ApiResponseRefresh: Codable {
    let success: Bool
    let data: RefreshResult
}
