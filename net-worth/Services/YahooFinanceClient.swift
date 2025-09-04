import Foundation

struct YahooFinanceClient {
    struct SearchResponse: Decodable {
        let quotes: [Quote]
    }
    struct Quote: Decodable, Identifiable, Hashable {
        var id: String { symbol }
        let symbol: String
        let shortname: String?
        let longname: String?
        let exchDisp: String?
        let typeDisp: String?
    }

    func search(query: String) async throws -> [Quote] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://query1.finance.yahoo.com/v1/finance/search?q=\(encoded)&quotesCount=20&newsCount=0")
        else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return []
        }
        let resp = try JSONDecoder().decode(SearchResponse.self, from: data)
        return resp.quotes
    }
}
