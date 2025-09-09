import Foundation

// Generic REST client usable across all entities
struct RestClient {
    let baseURL: URL
    init(baseURL: URL? = nil) {
        if let baseURL {
            self.baseURL = baseURL
        } else {
            #if targetEnvironment(simulator)
                // Running on iOS Simulator: talk to local backend
                self.baseURL = URL(string: "http://localhost:8080")!
            #else
                // Running on a physical device: use production backend
                self.baseURL = URL(string: "https://kfgx37r84g.execute-api.ap-south-1.amazonaws.com/prod")!
            #endif
        }
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
        // If absolute URL, return as-is
        if let absolute = URL(string: path), absolute.scheme != nil { return absolute }

        // Support query strings in the provided path (e.g., "transactions?accountId=1")
        let parts = path.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let rawPath = String(parts.first ?? "")
        let rawQuery = parts.count > 1 ? String(parts[1]) : nil

        // Build base path by appending components
        var url = baseURL
        let trimmed = rawPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        for comp in trimmed.split(separator: "/") { url.appendPathComponent(String(comp)) }

        // Attach query using URLComponents to avoid encoding '?' into the path
        if let rawQuery {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comps?.percentEncodedQuery = rawQuery  // keep any existing encoding
            if let final = comps?.url { return final }
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
            // Handle specific status codes according to OpenAPI spec
            switch http.statusCode {
            case 200, 201, 204:
                // Success cases
                break
            case 400, 404, 409, 500:
                // Expected error cases with API error response
                if !dataIsBlank(data),
                    let apiError = try? JSONDecoder().decode(ApiError.self, from: data)
                {
                    throw APIError.apiError(http.statusCode, apiError)
                }
                throw APIError.badStatus(http.statusCode)
            default:
                // Unexpected status codes
                if !dataIsBlank(data),
                    let apiError = try? JSONDecoder().decode(ApiError.self, from: data)
                {
                    throw APIError.apiError(http.statusCode, apiError)
                }
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
        let (_, http) = try await perform(method: "PATCH", path: path, body: body)
        // Handle 204 No Content responses
        if http.statusCode == 204 {
            return
        }
    }

    func patch<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws
        -> Response
    {
        let (data, _) = try await perform(method: "PATCH", path: path, body: body)
        if dataIsBlank(data) {
            throw APIError.decoding(NSError(domain: "EmptyBody", code: -1))
        }
        do { return try JSONDecoder().decode(Response.self, from: data) } catch {
            throw APIError.decoding(error)
        }
    }

    func delete(_ path: String) async throws {
        let (_, http) = try await perform(method: "DELETE", path: path)
        // Handle 204 No Content responses
        if http.statusCode == 204 {
            return
        }
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

extension RestClient {
    func fetchIncomes(userId: Int) async throws -> [Income] {
        let response: ApiResponseIncomeList = try await get("incomes/\(userId)")
        return response.data
    }
    func fetchAccounts(userId: Int) async throws -> [AccountSummary] {
        let response: ApiResponseAccountSummaryList = try await get("accounts/\(userId)")
        return response.data
    }
    func fetchIncomeSources(userId: Int) async throws -> [IncomeSource] {
        let response: ApiResponseIncomeSourceList = try await get("income-sources/\(userId)")
        return response.data
    }
    func fetchIncomeTags(userId: Int) async throws -> [IncomeTag] {
        let response: ApiResponseIncomeTagList = try await get("income-tags/\(userId)")
        return response.data
    }
    func fetchWatchlists(userId: Int) async throws -> [WatchlistSummary] {
        let response: ApiResponseWatchlistSummaryList = try await get("watchlists/\(userId)")
        return response.data
    }
    func fetchWatchlistAccounts(watchlistId: Int) async throws -> [AccountSummary] {
        let response: ApiResponseAccountSummaryList = try await get(
            "watchlist-accounts/\(watchlistId)")
        return response.data
    }

    func fetchAccountWatchlists(accountId: Int) async throws -> [WatchlistSummary] {
        let response: ApiResponseWatchlistSummaryList = try await get(
            "account-watchlists/\(accountId)")
        return response.data
    }
    // MARK: - Holdings API (replaces AccountBroker)
    func fetchHoldings(accountId: Int) async throws -> [HoldingSummary] {
        let response: ApiResponseHoldingSummaryList = try await get("holdings/\(accountId)")
        return response.data
    }

    func createHolding(
        accountId: Int,
        name: String,
        symbol: String
    ) async throws -> Holding {
        let body = CreateHoldingRequest(
            accountId: accountId,
            name: name,
            symbol: symbol
        )
        let response: ApiResponseHolding = try await post("holdings", body: body)
        return response.data
    }

    func deleteHolding(id: Int) async throws {
        try await delete("holdings/\(id)")
    }

    // MARK: - Transactions API (updated for holdings)
    func fetchAccountTransactions(accountId: Int) async throws -> [Transaction] {
        let response: ApiResponseTransactionList = try await get(
            "transactions?accountId=\(accountId)")
        return response.data
    }

    // Legacy compatibility method
    func fetchLegacyAccountTransactions(accountId: Int) async throws -> [AccountTransaction] {
        let transactions = try await fetchAccountTransactions(accountId: accountId)
        return transactions.map { transaction in
            AccountTransaction(
                id: transaction.id,
                accountId: transaction.accountId,
                accountBrokerId: transaction.holdingId,
                transactionDate: transaction.txnDate + " 00:00:00",  // Convert date format
                value: transaction.value,
                invested: transaction.invested,
                operation: nil
            )
        }
    }

    func fetchHoldingTransactions(holdingId: Int) async throws -> [Transaction] {
        let response: ApiResponseTransactionList = try await get(
            "transactions?holdingId=\(holdingId)")
        return response.data
    }

    // Legacy compatibility method
    func fetchLegacyHoldingTransactions(holdingId: Int) async throws -> [AccountTransaction] {
        let transactions = try await fetchHoldingTransactions(holdingId: holdingId)
        return transactions.map { transaction in
            AccountTransaction(
                id: transaction.id,
                accountId: transaction.accountId,
                accountBrokerId: transaction.holdingId,
                transactionDate: transaction.txnDate + " 00:00:00",  // Convert date format
                value: transaction.value,
                invested: transaction.invested,
                operation: nil
            )
        }
    }

    func createTransaction(
        accountId: Int,
        holdingId: Int,
        txnDate: String,
        invested: Double,
        value: Double,
        mode: String = "add"
    ) async throws -> Transaction {
        let body = CreateTransactionRequest(
            accountId: accountId,
            holdingId: holdingId,
            txnDate: txnDate,
            invested: invested,
            value: value,
            mode: mode
        )
        let response: ApiResponseTransaction = try await post("transactions", body: body)
        return response.data
    }

    func deleteTransaction(id: Int) async throws {
        try await delete("transactions/\(id)")
    }

    // MARK: - Legacy Compatibility (for gradual migration)
    func fetchAccountBroker(accountId: Int) async throws -> [AccountBroker] {
        return try await fetchHoldings(accountId: accountId)
    }

    func fetchAccountBrokerTransactions(accountBrokerId: Int) async throws -> [AccountTransaction] {
        return try await fetchLegacyHoldingTransactions(holdingId: accountBrokerId)
    }
    // MARK: - Accounts (Create/Update/Delete)
    func createAccount(
        userId: Int,
        name: String,
        type: String,
        currency: String,
        isActive: Bool = true,
        needsDailyData: Bool = false
    ) async throws -> Account {
        let body = CreateAccountRequest(
            userId: userId,
            name: name,
            type: type,
            currency: currency,
            isActive: isActive,
            needsDailyData: needsDailyData
        )
        let response: ApiResponseAccount = try await post("accounts", body: body)
        return response.data
    }

    func updateAccount(
        id: Int,
        name: String? = nil,
        isActive: Bool? = nil
    ) async throws -> Account {
        let body = UpdateAccountRequest(name: name, isActive: isActive)
        let response: ApiResponseAccount = try await patch("accounts/\(id)", body: body)
        return response.data
    }

    func deleteAccount(id: Int) async throws {
        try await delete("accounts/\(id)")
    }

    // MARK: - Users API
    func createOrEnsureUser(externalUserId: String) async throws -> User {
        let body = CreateUserRequest(externalUserId: externalUserId)
        let response: ApiResponseUser = try await post("users", body: body)
        return response.data
    }
    func createWatchlist(userId: Int, name: String) async throws -> Watchlist {
        let body = CreateWatchlistRequest(userId: userId, name: name)
        let response: ApiResponseWatchlist = try await post("watchlists", body: body)
        return response.data
    }
    func deleteWatchlist(id: Int) async throws {
        try await delete("watchlists/\(id)")
    }
    func updateWatchlist(id: Int, name: String) async throws -> Watchlist {
        let body = UpdateWatchlistNameRequest(name: name)
        let response: ApiResponseWatchlist = try await patch("watchlists/\(id)", body: body)
        return response.data
    }
    func linkWatchlistAccount(watchlistId: Int, accountId: Int) async throws {
        let body = CreateWatchlistAccountLinkRequest(watchlistId: watchlistId, accountId: accountId)
        _ = try await perform(method: "POST", path: "watchlist-accounts", body: body)
    }
    // Remove an account from a watchlist
    func unlinkWatchlistAccount(watchlistId: Int, accountId: Int) async throws {
        let body = CreateWatchlistAccountLinkRequest(watchlistId: watchlistId, accountId: accountId)
        _ = try await perform(method: "DELETE", path: "watchlist-accounts", body: body)
    }
    func setDefaultIncomeSource(id: Int) async throws {
        try await patch("income-sources/\(id)", body: EmptyBody())
    }

    // MARK: - Income Sources API (Complete Implementation)
    func createIncomeSource(
        userId: Int,
        name: String,
        isDefault: Bool = false
    ) async throws -> IncomeSource {
        let body = CreateIncomeSourceRequest(userId: userId, name: name, isDefault: isDefault)
        let response: ApiResponseIncomeSource = try await post("income-sources", body: body)
        return response.data
    }

    func setDefaultIncomeSourceById(id: Int) async throws {
        try await patch("income-sources/\(id)", body: EmptyBody())
    }

    // MARK: - Income Tags API (Complete Implementation)
    func createIncomeTag(
        userId: Int,
        name: String,
        isDefault: Bool = false
    ) async throws -> IncomeTag {
        let body = CreateIncomeTagRequest(userId: userId, name: name, isDefault: isDefault)
        let response: ApiResponseIncomeTag = try await post("income-tags", body: body)
        return response.data
    }

    func setDefaultIncomeTag(id: Int) async throws {
        try await patch("income-tags/\(id)", body: EmptyBody())
    }

    // MARK: - User Management API
    func deleteUser(id: Int) async throws {
        try await delete("users/\(id)")
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

        let response: ApiResponseIncome = try await post("incomes", body: body)
        return response.data
    }

    // Register Firebase user UID with backend
    func registerFirebaseUser(uid: String) async throws -> Int {
        struct Payload: Codable { let externalUserId: String }
        let body = Payload(externalUserId: uid)
        let response: ApiResponseUser = try await post("users", body: body)
        return response.data.id
    }

    // MARK: - Chart Data API
    func fetchChartData(
        entityType: ChartEntityType,
        entityId: Int,
        timePeriod: ChartTimePeriod
    ) async throws -> [ChartData] {
        let path =
            "chart-data?entityType=\(entityType.rawValue)&entityId=\(entityId)&timePeriod=\(timePeriod.rawValue)"
        let response: ApiResponseChartDataList = try await get(path)
        return response.data
    }

}

// Note: Use RestClient directly going forward. A thin deprecated IncomeService wrapper
// remains to preserve source compatibility.
