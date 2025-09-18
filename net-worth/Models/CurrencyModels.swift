import Foundation

struct Currency: Identifiable, Hashable {
    let name: String
    let code: String
    let symbol: String
    var id: String { code }
}

/// Provides a catalog of world currencies (ISO 4217) with localized names and symbols.
/// The list is derived from the system's currency tables to avoid maintaining a hardcoded list.
final class CurrencyCatalog {
    /// All known ISO 4217 currencies available on the platform, sorted by localized name.
    static let all: [Currency] = {
        // Use NSLocale.isoCurrencyCodes for widest compatibility across iOS versions
        let codes = (NSLocale.isoCurrencyCodes as [String])
        let loc = Locale.current
        return codes.compactMap { code in
            let name = loc.localizedString(forCurrencyCode: code) ?? code
            let nf = NumberFormatter()
            nf.numberStyle = .currency
            nf.currencyCode = code
            let symbol = nf.currencySymbol ?? code
            return Currency(name: name, code: code, symbol: symbol)
        }
        .sorted { a, b in
            a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }()

    /// Fast lookup by currency code (uppercased)
    static let byCode: [String: Currency] = {
        var map: [String: Currency] = [:]
        for c in all { map[c.code.uppercased()] = c }
        return map
    }()
}
