import Foundation

// Generic REST client usable across all entities
struct RestClient {
    let baseURL: URL
    init(
        baseURL: URL = URL(string: "https://lz2oz2v0ul.execute-api.ap-south-1.amazonaws.com/prod")!
        // baseURL: URL = URL(string: "http://localhost:8080")!
    ) {
        self.baseURL = baseURL
    }

    // MARK: - Utilities
    private func dataIsBlank(_ data: Data) -> Bool {
        if data.isEmpty { return true }
        if let s = String(data: data, encoding: .utf8)?.trimmingCharacters(
            in: .whitespacesAndNewlines)
        {
            if s.isEmpty || s.lowercased() == "null" { return true }
        }
        for b in data {  // space, tab, newline, carriage return
            if b != 0x20 && b != 0x09 && b != 0x0A && b != 0x0D { return false }
        }
        return true
    }

    private func resolvedURL(for path: String) throws -> URL {
        if let absolute = URL(string: path), absolute.scheme != nil {
            return absolute
        }
        var url = baseURL
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        for comp in trimmed.split(separator: "/") {
            url.appendPathComponent(String(comp))
        }
        return url
    }

    private func perform(
        method: String, path: String, body: (any Encodable)? = nil,
        additionalHeaders: [String: String] = [:]
    ) async throws -> (Data, HTTPURLResponse) {
        let url = try resolvedURL(for: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        for (k, v) in additionalHeaders { request.setValue(v, forHTTPHeaderField: k) }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.badStatus(-1) }
            guard (200...299).contains(http.statusCode) else {
                throw APIError.badStatus(http.statusCode)
            }
            return (data, http)
        } catch let apiErr as APIError {
            throw apiErr
        } catch {
            throw APIError.transport(error)
        }
    }

    // MARK: - Generic verbs
    func get<R: Decodable>(_ path: String) async throws -> R {
        let (data, _) = try await perform(method: "GET", path: path)
        do {
            return try JSONDecoder().decode(R.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func getList<E: Decodable>(_ path: String) async throws -> [E] {
        let (data, _) = try await perform(method: "GET", path: path)
        if dataIsBlank(data) { return [] }
        do { return try JSONDecoder().decode([E].self, from: data) } catch {
            throw APIError.decoding(error)
        }
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws
        -> Response
    {
        let (data, _) = try await perform(method: "POST", path: path, body: body)
        if dataIsBlank(data) {
            // Server returned no body; decoding will fail — surface a decoding error for caller to decide.
            throw APIError.decoding(NSError(domain: "EmptyBody", code: -1))
        }
        do { return try JSONDecoder().decode(Response.self, from: data) } catch {
            throw APIError.decoding(error)
        }
    }

    // POST that can return entity or a minimal id object; caller provides fallback synthesizer
    func postWithFallback<Body: Encodable, Response>(
        _ path: String, body: Body, synthesize: (Int?) -> Response
    ) async throws -> Response where Response: Decodable {
        let (data, _) = try await perform(method: "POST", path: path, body: body)
        if dataIsBlank(data) { return synthesize(nil) }
        // Try full entity first
        if let entity = try? JSONDecoder().decode(Response.self, from: data) { return entity }
        // Try minimal id response: {"result":"success","id":N}
        if let minimal = try? JSONDecoder().decode(MinimalIdResponse.self, from: data) {
            return synthesize(minimal.id)
        }
        // Fallback
        return synthesize(nil)
    }

    func patch<Body: Encodable>(_ path: String, body: Body) async throws {
        _ = try await perform(method: "PATCH", path: path, body: body)
    }

    func delete(_ path: String) async throws {
        _ = try await perform(method: "DELETE", path: path)
    }

    // Update an income record
    func updateIncome(
        id: Int,
        userId: Int,
        amount: Double,
        taxPaid: Double,
        creditedDate: Date,
        currency: String,
        incomeType: IncomeType,
        incomeTag: IncomeTag
    ) async throws {
        // Always send backend datetime as IST midnight for the user's selected calendar date
        let dateString = DateTZ.toBackendISTString(fromUserDate: creditedDate)

        struct Payload: Codable {
            let id: Int
            let userId: Int
            let amount: Double
            let taxPaid: Double
            let creditedDate: String
            let currency: String
            let incomeType: IncomeType
            let incomeTag: IncomeTag
        }
        let body = Payload(
            id: id,
            userId: userId,
            amount: amount,
            taxPaid: taxPaid,
            creditedDate: dateString,
            currency: currency,
            incomeType: incomeType,
            incomeTag: incomeTag
        )

        try await patch("income", body: body)
    }
}

// Helper to encode existential Encodable
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { self.encodeFunc = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}

// Minimal id-only response sometimes returned by POST endpoints
private struct MinimalIdResponse: Decodable {
    let result: String?
    let id: Int?
}

// MARK: - Backward-compatible conveniences for current entities
extension RestClient {
    func fetchIncomes(userId: Int) async throws -> [Income] {
        try await getList("income/\(userId)")
    }
    func fetchAccounts(userId: Int) async throws -> [Account] {
        try await getList("account/\(userId)")
    }
    func fetchIncomeTypes(userId: Int) async throws -> [IncomeType] {
        try await getList("income_type/\(userId)")
    }
    func fetchIncomeTags(userId: Int) async throws -> [IncomeTag] {
        try await getList("income_tag/\(userId)")
    }
    func fetchWatchlists(userId: Int) async throws -> [Watchlist] {
        try await getList("watch/\(userId)")
    }
    func fetchWatchAccounts(watchId: Int) async throws -> [WatchAccount] {
        try await getList("watch_account/\(watchId)/watch")
    }
    func fetchAccountBroker(accountId: Int) async throws -> [AccountBroker] {
        try await getList("account_broker/\(accountId)")
    }
    func fetchAccountTransactions(accountId: Int) async throws -> [AccountTransaction] {
        try await getList("account_transaction/\(accountId)/account")
    }
    // MARK: - Accounts (Create/Delete)
    func createAccount(
        userId: Int,
        name: String,
        type: String,
        currency: String,
        active: Bool,
        value: AccountValue = AccountValue(currentValue: 0, previousValue: 0, invested: 0)
    ) async throws -> Account {
        struct Payload: Codable {
            let userId: Int
            let name: String
            let type: String
            let currency: String
            let active: Bool
            let value: AccountValue
        }
        let body = Payload(
            userId: userId, name: name, type: type, currency: currency, active: active, value: value
        )
        return try await postWithFallback("account", body: body) { newId in
            Account(
                id: newId ?? -1,
                userId: userId,
                name: name,
                type: type,
                currency: currency,
                active: active,
                value: value
            )
        }
    }
    func deleteAccount(id: Int) async throws {
        try await delete("account/\(id)")
    }
    func createWatchlist(userId: Int, name: String) async throws -> Watchlist {
        struct Payload: Codable {
            let userId: Int
            let name: String
        }
        let body = Payload(userId: userId, name: name)
        return try await postWithFallback("watch", body: body) { newId in
            Watchlist(
                id: newId ?? -1,
                userId: userId,
                name: name,
                totalAccount: 0,
                value: WatchlistValue(currentValue: 0, previousValue: 0, invested: 0)
            )
        }
    }
    func deleteWatchlist(id: Int) async throws {
        try await delete("watch/\(id)")
    }
    func updateWatchlist(id: Int, userId: Int, name: String) async throws {
        struct Payload: Codable {
            let id: Int
            let userId: Int
            let name: String
        }
        try await patch("watch", body: Payload(id: id, userId: userId, name: name))
    }
    func createWatchAccount(accountId: Int, watchId: Int) async throws -> WatchAccount {
        struct Payload: Codable {
            let accountId: Int
            let watchId: Int
        }
        let body = Payload(accountId: accountId, watchId: watchId)
        return try await postWithFallback("watch_account", body: body) { newId in
            WatchAccount(id: newId ?? -1, accountId: accountId, watchId: watchId)
        }
    }
    // Remove an account from a watchlist by link id
    func deleteWatchAccount(id: Int) async throws {
        try await delete("watch_account/\(id)")
    }
    /// Permanently delete the user and all server-side data
    func deleteUser(id: Int) async throws {
        try await delete("user/\(id)")
    }
    func setDefault(incomeType: IncomeType) async throws {
        let payload = IncomeType(
            id: incomeType.id, userId: incomeType.userId, name: incomeType.name, isDefault: true)
        try await patch("income_type", body: payload)
    }
    func setDefault(incomeTag: IncomeTag) async throws {
        let payload = IncomeTag(
            id: incomeTag.id, userId: incomeTag.userId, name: incomeTag.name, isDefault: true)
        try await patch("income_tag", body: payload)
    }
    func createIncomeType(userId: Int, name: String, isDefault: Bool) async throws -> IncomeType {
        struct Payload: Codable {
            let userId: Int
            let name: String
            let isDefault: Bool
        }
        let body = Payload(userId: userId, name: name, isDefault: isDefault)
        return try await postWithFallback("income_type", body: body) { newId in
            IncomeType(id: newId ?? -1, userId: userId, name: name, isDefault: isDefault)
        }
    }
    func createIncomeTag(userId: Int, name: String, isDefault: Bool) async throws -> IncomeTag {
        struct Payload: Codable {
            let userId: Int
            let name: String
            let isDefault: Bool
        }
        let body = Payload(userId: userId, name: name, isDefault: isDefault)
        return try await postWithFallback("income_tag", body: body) { newId in
            IncomeTag(id: newId ?? -1, userId: userId, name: name, isDefault: isDefault)
        }
    }

    func deleteIncome(id: Int) async throws {
        try await delete("income/\(id)")
    }

    // Create an income record
    func createIncome(
        userId: Int,
        amount: Double,
        taxPaid: Double,
        creditedDate: Date,
        currency: String,
        incomeType: IncomeType,
        incomeTag: IncomeTag
    ) async throws -> Income {
        // Always send backend datetime as IST midnight for the user's selected calendar date
        let dateString = DateTZ.toBackendISTString(fromUserDate: creditedDate)
        // For local synthesized Income (when backend returns only id), keep user's local midnight
        let midnightLocal = Calendar.current.startOfDay(for: creditedDate)

        struct Payload: Codable {
            let userId: Int
            let amount: Double
            let taxPaid: Double
            let creditedDate: String
            let currency: String
            let incomeType: IncomeType
            let incomeTag: IncomeTag
        }
        let body = Payload(
            userId: userId,
            amount: amount,
            taxPaid: taxPaid,
            creditedDate: dateString,
            currency: currency,
            incomeType: incomeType,
            incomeTag: incomeTag
        )

        return try await postWithFallback("income", body: body) { newId in
            // Synthesize minimal Income when backend returns only an id
            Income(
                id: newId ?? -1,
                userId: userId,
                amount: amount,
                taxPaid: taxPaid,
                creditedDate: midnightLocal,
                currency: currency,
                incomeType: incomeType,
                incomeTag: incomeTag
            )
        }
    }

    // Register Firebase user UID with backend
    func registerFirebaseUser(uid: String) async throws -> Int {
        struct Payload: Codable { let userId: String }
        let body = Payload(userId: uid)
        let response: MinimalIdResponse = try await post("user", body: body)
        return response.id ?? -1
    }
}

// Note: Use RestClient directly going forward. A thin deprecated IncomeService wrapper
// remains to preserve source compatibility.
