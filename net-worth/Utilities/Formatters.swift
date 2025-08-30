import Foundation

extension DateFormatter {
    static let incomeBackend: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return df
    }()
    
    static let incomeBackendDateTime: DateFormatter = {
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

// MARK: - Time zone and backend date helpers
extension TimeZone {
    static let ist = TimeZone(identifier: "Asia/Kolkata")!
}

enum DateTZ {
    static let ist = TimeZone.ist

    // Build backend date string in IST midnight for the user's selected calendar date
    static func toBackendISTString(fromUserDate date: Date) -> String {
        var calUser = Calendar(identifier: .gregorian)
        calUser.timeZone = .current
        let comps = calUser.dateComponents([.year, .month, .day], from: date)
        var calIST = Calendar(identifier: .gregorian)
        calIST.timeZone = ist
        let istMidnight = calIST.date(
            from: DateComponents(
                calendar: calIST,
                timeZone: ist,
                year: comps.year, month: comps.month, day: comps.day,
                hour: 0, minute: 0, second: 0
            )
        ) ?? date
        return DateFormatter.incomeBackendDateTime.string(from: istMidnight)
    }

    // Parse IST backend date string and convert to user's local midnight for the same calendar date
    static func fromBackendISTStringToUserDate(_ s: String) -> Date? {
        // Parse as IST
        guard let istInstant = DateFormatter.incomeBackendDateTime.date(from: s) else { return nil }
        // Extract IST Y-M-D
        var calIST = Calendar(identifier: .gregorian)
        calIST.timeZone = ist
        let comps = calIST.dateComponents([.year, .month, .day], from: istInstant)
        // Rebuild at midnight in the user's current timezone for the same Y-M-D
        var calUser = Calendar(identifier: .gregorian)
        calUser.timeZone = .current
        return calUser.date(
            from: DateComponents(
                calendar: calUser,
                timeZone: .current,
                year: comps.year, month: comps.month, day: comps.day,
                hour: 0, minute: 0, second: 0
            )
        )
    }
}
