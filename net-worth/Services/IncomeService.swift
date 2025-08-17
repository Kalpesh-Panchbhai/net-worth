import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case decoding(Error)
    case transport(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .badStatus(let code):
            if (500...599).contains(code) { return "The server is having a problem (\(code)). Please try again." }
            if code == 404 { return "Requested resource was not found (404)." }
            if code == 401 { return "You’re not authorized to perform this action (401)." }
            return "Server responded with status: \(code)"
        case .decoding:
            return "We couldn’t read the server response. Please try again."
        case .transport(let err):
            if let urlErr = err as? URLError {
                switch urlErr.code {
                case .notConnectedToInternet:
                    return "You’re offline. Check your internet connection and try again."
                case .timedOut:
                    return "The request timed out. Please try again."
                case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                    return "Can’t reach the server. Please try again."
                case .networkConnectionLost:
                    return "The network connection was lost."
                default:
                    return "Network error: \(urlErr.localizedDescription)"
                }
            }
            return "Network error: \(err.localizedDescription)"
        }
    }
}

struct IncomeService {
    let baseURL: URL
    init(baseURL: URL = URL(string: "http://localhost:8080")!) {
        self.baseURL = baseURL
    }
    private func dataIsBlank(_ data: Data) -> Bool {
        if data.isEmpty { return true }
        // If the payload is only whitespace or the literal string "null", treat as blank
        if let s = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if s.isEmpty || s.lowercased() == "null" { return true }
        }
        for b in data { // space, tab, newline, carriage return
            if b != 0x20 && b != 0x09 && b != 0x0A && b != 0x0D { return false }
        }
        return true
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
                if dataIsBlank(data) { return [] }
                return try decoder.decode([Income].self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch let apiErr as APIError {
            throw apiErr
        } catch {
            throw APIError.transport(error)
        }
    }

    func fetchIncomeTypes(userId: Int) async throws -> [IncomeType] {
        let url = baseURL.appendingPathComponent("income_type").appendingPathComponent(String(userId))
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
            do {
                let decoder = JSONDecoder()
                if dataIsBlank(data) { return [] }
                return try decoder.decode([IncomeType].self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch let apiErr as APIError {
            throw apiErr
        } catch {
            throw APIError.transport(error)
        }
    }

    func fetchIncomeTags(userId: Int) async throws -> [IncomeTag] {
        let url = baseURL.appendingPathComponent("income_tag").appendingPathComponent(String(userId))
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
            do {
                let decoder = JSONDecoder()
                if dataIsBlank(data) { return [] }
                return try decoder.decode([IncomeTag].self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch let apiErr as APIError {
            throw apiErr
        } catch {
            throw APIError.transport(error)
        }
    }

    // MARK: - Set Default (PATCH)
    func setDefault(incomeType: IncomeType) async throws {
        let url = baseURL.appendingPathComponent("income_type")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = IncomeType(id: incomeType.id, userId: incomeType.userId, name: incomeType.name, isDefault: true)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(payload)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
        } catch {
            throw APIError.transport(error)
        }
    }

    func setDefault(incomeTag: IncomeTag) async throws {
        let url = baseURL.appendingPathComponent("income_tag")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = IncomeTag(id: incomeTag.id, userId: incomeTag.userId, name: incomeTag.name, isDefault: true)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(payload)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
        } catch {
            throw APIError.transport(error)
        }
    }

    // MARK: - Create (POST)
    func createIncomeType(userId: Int, name: String, isDefault: Bool) async throws -> IncomeType {
        let url = baseURL.appendingPathComponent("income_type")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Payload: Codable { let userId: Int; let name: String; let isDefault: Bool }
        let payload = Payload(userId: userId, name: name, isDefault: isDefault)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(payload)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
            if dataIsBlank(data) {
                return IncomeType(id: -1, userId: userId, name: name, isDefault: isDefault)
            }
            // Try to decode a full entity first
            if let entity = try? JSONDecoder().decode(IncomeType.self, from: data) { return entity }
            // Try to decode a minimal id response: {"result":"success","id":14}
            struct Minimal: Decodable { let result: String?; let id: Int? }
            if let minimal = try? JSONDecoder().decode(Minimal.self, from: data), let newId = minimal.id {
                return IncomeType(id: newId, userId: userId, name: name, isDefault: isDefault)
            }
            // Fallback: synthesize with temp id
            return IncomeType(id: -1, userId: userId, name: name, isDefault: isDefault)
        } catch {
            throw APIError.transport(error)
        }
    }

    func createIncomeTag(userId: Int, name: String, isDefault: Bool) async throws -> IncomeTag {
        let url = baseURL.appendingPathComponent("income_tag")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Payload: Codable { let userId: Int; let name: String; let isDefault: Bool }
        let payload = Payload(userId: userId, name: name, isDefault: isDefault)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(payload)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else { throw APIError.badStatus(http.statusCode) }
            if dataIsBlank(data) {
                return IncomeTag(id: -1, userId: userId, name: name, isDefault: isDefault)
            }
            if let entity = try? JSONDecoder().decode(IncomeTag.self, from: data) { return entity }
            struct Minimal: Decodable { let result: String?; let id: Int? }
            if let minimal = try? JSONDecoder().decode(Minimal.self, from: data), let newId = minimal.id {
                return IncomeTag(id: newId, userId: userId, name: name, isDefault: isDefault)
            }
            return IncomeTag(id: -1, userId: userId, name: name, isDefault: isDefault)
        } catch {
            throw APIError.transport(error)
        }
    }
}
