import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case decoding(Error)
    case transport(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .badStatus(let code): return "Server responded with status: \(code)"
        case .decoding(let err): return "Failed to decode response: \(err.localizedDescription)"
        case .transport(let err): return "Network error: \(err.localizedDescription)"
        }
    }
}

struct IncomeService {
    let baseURL: URL
    init(baseURL: URL = URL(string: "http://localhost:8080")!) {
        self.baseURL = baseURL
    }
    
    func fetchIncomes(userId: Int) async throws -> [Income] {
        let url = baseURL.appendingPathComponent("income").appendingPathComponent(String(userId))
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
            do {
                let decoder = JSONDecoder()
                return try decoder.decode([Income].self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch {
            throw APIError.transport(error)
        }
    }
}
