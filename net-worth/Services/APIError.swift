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
