import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case apiError(Int, ApiError)
    case decoding(Error)
    case transport(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .badStatus(let code):
            if (500...599).contains(code) { return "The server is having a problem (\(code)). Please try again." }
            if code == 404 { return "Requested resource was not found (404)." }
            if code == 401 { return "You're not authorized to perform this action (401)." }
            if code == 409 { return "A conflict occurred. This resource may already exist or violate a constraint." }
            if code == 400 { return "Invalid request. Please check your input and try again." }
            return "Server responded with status: \(code)"
        case .apiError(let code, let apiError):
            // Prefer clean, human-friendly messages from server.
            // 409 conflicts (e.g., duplicate names) should not show technical suffixes.
            if code == 409 {
                var msg = apiError.message
                // Remove noisy suffix commonly returned by backend
                msg = msg.replacingOccurrences(of: " for this user", with: "", options: .caseInsensitive)
                // Collapse any double spaces left after removal
                msg = msg.replacingOccurrences(of: "  ", with: " ")
                msg = msg.trimmingCharacters(in: .whitespacesAndNewlines)
                return msg.isEmpty ? "Conflict. This item may already exist." : msg
            }
            // For other statuses, still return the server message (fallback to generic if empty).
            return apiError.message.isEmpty ? "Request failed (\(code)). Please try again." : apiError.message
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
                    return "The connection was lost. Please try again."
                case .cancelled:
                    // Silent cancellation (e.g., user-initiated refresh overlap). Don’t show a banner.
                    return nil
                default:
                    return "Request failed: \(urlErr.localizedDescription)"
                }
            }
            return "Request failed: \(err.localizedDescription)"
        }
    }
}
