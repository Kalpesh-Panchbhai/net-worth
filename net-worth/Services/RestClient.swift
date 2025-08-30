import Foundation

// Generic REST client usable across all entities
struct RestClient {
    let baseURL: URL
    init(
        // baseURL: URL = URL(string: "https://lz2oz2v0ul.execute-api.ap-south-1.amazonaws.com/prod")!
        baseURL: URL = URL(string: "http://localhost:8080")!
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
    
    func patch<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        let (data, _) = try await perform(method: "PATCH", path: path, body: body)
        if dataIsBlank(data) {
            throw APIError.decoding(NSError(domain: "EmptyBody", code: -1))
        }
        do { return try JSONDecoder().decode(Response.self, from: data) } catch {
            throw APIError.decoding(error)
        }
    }

    func delete(_ path: String) async throws {
        _ = try await perform(method: "DELETE", path: path)
    }

    // Update an income record
    func updateIncome(
        id: Int,
        incomeSourceId: Int? = nil,
        incomeTagId: Int? = nil,
        netAmount: Double? = nil,
        taxPaid: Double? = nil,
        creditedDate: Date? = nil,
        currency: String? = nil
    ) async throws -> Income {
        let dateString = creditedDate.map { 
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: $0)
        }
        let body = UpdateIncomeRequest(
            incomeSourceId: incomeSourceId,
            incomeTagId: incomeTagId,
            netAmount: netAmount,
            taxPaid: taxPaid,
            currency: currency,
            creditedDate: dateString
        )
        
        let response: ApiResponse<Income> = try await patch("incomes/\(id)", body: body)
        return response.data
    }
}

// Helper to encode existential Encodable
private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { self.encodeFunc = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}

// Empty body for PATCH requests that don't need a body
private struct EmptyBody: Codable {}

// Minimal id-only response sometimes returned by POST endpoints
private struct MinimalIdResponse: Decodable {
    let result: String?
    let id: Int?
}

// MARK: - Backward-compatible conveniences for current entities
extension RestClient {
    func fetchIncomes(userId: Int) async throws -> [Income] {
        let response: ApiResponse<[Income]> = try await get("incomes/\(userId)")
        return response.data
    }
    func fetchAccounts(userId: Int) async throws -> [Account] {
        try await getList("accounts/\(userId)")
    }
    func fetchIncomeSources(userId: Int) async throws -> [IncomeSource] {
        let response: ApiResponse<[IncomeSource]> = try await get("income-sources/\(userId)")
        return response.data
    }
    func fetchIncomeTags(userId: Int) async throws -> [IncomeTag] {
        let response: ApiResponse<[IncomeTag]> = try await get("income-tags/\(userId)")
        return response.data
    }
    func fetchWatchlists(userId: Int) async throws -> [Watchlist] {
        try await getList("watch/\(userId)")
    }
    func fetchWatchAccounts(watchId: Int) async throws -> [WatchAccount] {
        try await getList("watch_account/\(watchId)/watch")
    }
    func fetchWatchAccountsByAccount(accountId: Int) async throws -> [WatchAccount] {
        try await getList("watch_account/\(accountId)/account")
    }
    func fetchAccountBroker(accountId: Int) async throws -> [AccountBroker] {
        try await getList("account_broker/\(accountId)")
    }
    func fetchAccountTransactions(accountId: Int) async throws -> [AccountTransaction] {
        try await getList("account_transaction/\(accountId)/account")
    }
    func fetchAccountBrokerTransactions(accountBrokerId: Int) async throws -> [AccountTransaction] {
        try await getList("account_transaction/\(accountBrokerId)/account_broker")
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
    // Create an account transaction (for account or broker holding)
    func createAccountTransaction(
        accountId: Int,
        accountBrokerId: Int,
        transactionDate: Date,
        value: Double,
        operation: String
    ) async throws -> AccountTransaction {
        struct Payload: Codable {
            let accountId: Int
            let accountBrokerId: Int
            let transactionDate: String
            let value: Double
            let operation: String
        }
        let dateString = DateTZ.toBackendISTString(fromUserDate: transactionDate)
        let body = Payload(
            accountId: accountId,
            accountBrokerId: accountBrokerId,
            transactionDate: dateString,
            value: value,
            operation: operation
        )
        return try await postWithFallback("account_transaction", body: body) { newId in
            AccountTransaction(
                id: newId ?? -1,
                accountId: accountId,
                accountBrokerId: accountBrokerId,
                transactionDate: dateString,
                value: value,
                operation: operation
            )
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
    func setDefaultIncomeSource(id: Int) async throws {
        try await patch("income-sources/\(id)", body: EmptyBody())
    }
    
    func setDefaultIncomeTag(id: Int) async throws {
        try await patch("income-tags/\(id)", body: EmptyBody())
    }
    
    func createIncomeSource(userId: Int, name: String, isDefault: Bool = false) async throws -> IncomeSource {
        let body = CreateIncomeSourceRequest(userId: userId, name: name, isDefault: isDefault)
        let response: ApiResponse<IncomeSource> = try await post("income-sources", body: body)
        return response.data
    }
    
    func createIncomeTag(userId: Int, name: String, isDefault: Bool = false) async throws -> IncomeTag {
        let body = CreateIncomeTagRequest(userId: userId, name: name, isDefault: isDefault)
        let response: ApiResponse<IncomeTag> = try await post("income-tags", body: body)
        return response.data
    }

    func deleteIncome(id: Int) async throws {
        try await delete("incomes/\(id)")
    }

    // Create an income record
    func createIncome(
        userId: Int,
        incomeSourceId: Int,
        incomeTagId: Int,
        netAmount: Double,
        taxPaid: Double? = nil,
        creditedDate: Date,
        currency: String
    ) async throws -> Income {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: creditedDate)
        
        let body = CreateIncomeRequest(
            userId: userId,
            incomeSourceId: incomeSourceId,
            incomeTagId: incomeTagId,
            netAmount: netAmount,
            taxPaid: taxPaid,
            currency: currency,
            creditedDate: dateString
        )
        
        let response: ApiResponse<Income> = try await post("incomes", body: body)
        return response.data
    }

    // Register Firebase user UID with backend
    func registerFirebaseUser(uid: String) async throws -> Int {
        struct Payload: Codable { let externalUserId: String }
        let body = Payload(externalUserId: uid)
        let response: ApiResponse<User> = try await post("users", body: body)
        return response.data.id
    }
    
    struct User: Codable {
        let id: Int
        let externalUserId: String
    }
}

// Note: Use RestClient directly going forward. A thin deprecated IncomeService wrapper
// remains to preserve source compatibility.
