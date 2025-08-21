import Foundation

extension DateFormatter {
    static let incomeBackend: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return df
    }()

    static let monthYear: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "LLLL yyyy"
        return df
    }()

    static let dayMonYear: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        return df
    }()
}

// MARK: - Currency Short Formatter (with Indian numbering for INR)
enum CurrencyShort {
    static func symbol(for code: String) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = code
        return nf.currencySymbol ?? code
    }
    
    static func shortString(_ amount: Double, currency: String) -> String {
        let sym = symbol(for: currency)
        let absVal = abs(amount)
        let sign = amount < 0 ? "-" : ""
        func fmt(_ value: Double, places: Int = 2) -> String {
            String(format: "%0.*f", places, value)
        }
        let nbsp = "\u{00A0}" // non‑breaking space to keep suffix with number
        if currency.uppercased() == "INR" {
            if absVal >= 1.0e7 { // Crore
                return "\(sign)\(sym)\(fmt(absVal/1.0e7))\(nbsp)Cr"
            } else if absVal >= 1.0e5 { // Lakh
                return "\(sign)\(sym)\(fmt(absVal/1.0e5))\(nbsp)L"
            } else if absVal >= 1.0e3 { // Thousand
                return "\(sign)\(sym)\(fmt(absVal/1.0e3, places: 1))\(nbsp)K"
            } else {
                return amount.formatted(.currency(code: currency))
            }
        } else {
            if absVal >= 1.0e9 { return "\(sign)\(sym)\(fmt(absVal/1.0e9))\(nbsp)B" }
            if absVal >= 1.0e6 { return "\(sign)\(sym)\(fmt(absVal/1.0e6))\(nbsp)M" }
            if absVal >= 1.0e3 { return "\(sign)\(sym)\(fmt(absVal/1.0e3, places: 1))\(nbsp)K" }
            return amount.formatted(.currency(code: currency))
        }
    }
}
