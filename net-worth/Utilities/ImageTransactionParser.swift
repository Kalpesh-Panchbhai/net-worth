import Foundation

/// Parser to extract transaction details from recognized text
struct ImageTransactionParser {
    
    struct ParsedTransaction {
        let amount: Double
        let invested: Double?
        let date: Date
    }
    
    /// Parse transaction details from extracted text lines
    /// - Parameter textLines: Array of text strings extracted from image
    /// - Returns: ParsedTransaction with amount, invested (if available), and date
    static func parse(from textLines: [String]) throws -> ParsedTransaction {
        // Detect if this is an investment screenshot or bank balance
        let isInvestmentScreen = detectInvestmentScreen(in: textLines)
        
        if isInvestmentScreen {
            // For investment screens: extract Current Value and Invested Amount
            guard let (currentValue, investedAmount) = findInvestmentAmounts(in: textLines) else {
                throw ParserError.amountNotFound
            }
            // Try to find date from screenshot, fallback to today
            let date = findDate(in: textLines) ?? Date()
            return ParsedTransaction(amount: currentValue, invested: investedAmount, date: date)
        } else {
            // For bank balance screens: extract only the main balance
            guard let amount = findBankBalance(in: textLines) else {
                throw ParserError.amountNotFound
            }
            let date = Date() // Always today
            return ParsedTransaction(amount: amount, invested: amount, date: date)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Detect if this is an investment portfolio screenshot
    private static func detectInvestmentScreen(in textLines: [String]) -> Bool {
        let investmentKeywords = [
            "current value",
            "invested amount",
            "returns",
            "portfolio",
            "fund holdings",
            "equity",
            "mutual fund"
        ]
        
        let allText = textLines.joined(separator: " ").lowercased()
        return investmentKeywords.contains { allText.contains($0) }
    }
    
    /// Find Current Value and Invested Amount from investment screenshots
    private static func findInvestmentAmounts(in textLines: [String]) -> (currentValue: Double, invested: Double)? {
        var currentValue: Double?
        var investedAmount: Double?
        var foundMainCurrentValue = false
        
        // Look for "Current Value" and the amount in nearby lines
        for (index, line) in textLines.enumerated() {
            let lowerLine = line.lowercased()
            
            // Check for "Current Value" - but only take the FIRST occurrence (main portfolio value)
            if !foundMainCurrentValue && (lowerLine.contains("current value") || lowerLine.contains("current val")) {
                // Avoid sub-sections like "Equity", "Government Bonds", "Fund Holdings"
                let isSubSection = lowerLine.contains("equity") || 
                                  lowerLine.contains("bond") || 
                                  lowerLine.contains("fund holdings") ||
                                  lowerLine.contains("units")
                
                if !isSubSection {
                    // Look in current line and next few lines for the amount
                    for offset in 0...3 {
                        if index + offset < textLines.count {
                            let searchLine = textLines[index + offset]
                            // Skip lines that look like sub-headers
                            let searchLineLower = searchLine.lowercased()
                            if searchLineLower.contains("equity") || 
                               searchLineLower.contains("bond") || 
                               searchLineLower.contains("units") {
                                continue
                            }
                            
                            if let amount = extractLargestAmount(from: searchLine) {
                                // Ensure it's a substantial amount (> 10,000 for main portfolio)
                                if amount > 10000 {
                                    currentValue = amount
                                    foundMainCurrentValue = true
                                    break
                                }
                            }
                        }
                    }
                }
            }
            
            // Check for "Invested Amount" - only take the FIRST occurrence
            if investedAmount == nil && (lowerLine.contains("invested amount") || 
                (lowerLine.contains("invested") && !lowerLine.contains("units"))) {
                // Avoid sub-sections
                let isSubSection = lowerLine.contains("equity") || 
                                  lowerLine.contains("bond") || 
                                  lowerLine.contains("fund holdings") ||
                                  lowerLine.contains("returns")
                
                if !isSubSection {
                    // Look in current line and next few lines for the amount
                    for offset in 0...3 {
                        if index + offset < textLines.count {
                            let searchLine = textLines[index + offset]
                            // Skip lines that look like sub-headers or returns
                            let searchLineLower = searchLine.lowercased()
                            if searchLineLower.contains("returns") || 
                               searchLineLower.contains("equity") || 
                               searchLineLower.contains("bond") {
                                continue
                            }
                            
                            if let amount = extractLargestAmount(from: searchLine) {
                                // Ensure it's a substantial amount
                                if amount > 1000 {
                                    investedAmount = amount
                                    break
                                }
                            }
                        }
                    }
                }
            }
            
            // Early exit if we found both
            if foundMainCurrentValue && investedAmount != nil {
                break
            }
        }
        
        // Return both if found
        if let current = currentValue, let invested = investedAmount {
            return (current, invested)
        }
        return nil
    }
    
    /// Find bank balance from bank balance screenshots (only the main large amount)
    private static func findBankBalance(in textLines: [String]) -> Double? {
        // Look specifically for lines near "Bank balance" text
        for (index, line) in textLines.enumerated() {
            let lowerLine = line.lowercased()
            
            if lowerLine.contains("bank balance") {
                // Search in the next 3 lines for the largest amount
                var amounts: [Double] = []
                for offset in 0...3 {
                    if index + offset < textLines.count {
                        let searchLine = textLines[index + offset]
                        if let amount = extractLargestAmount(from: searchLine) {
                            amounts.append(amount)
                        }
                    }
                }
                // Return the largest amount found (should be the main balance)
                return amounts.max()
            }
        }
        
        // Fallback: find the largest amount in the entire text
        return findAmount(in: textLines)
    }
    
    /// Extract the largest amount from a single line
    private static func extractLargestAmount(from line: String) -> Double? {
        let rupeeSymbols = ["₹", "Rs", "Rs.", "INR", "र", "₨"]
        var amounts: [Double] = []
        
        // Try with rupee symbols
        for symbol in rupeeSymbols {
            if line.contains(symbol) {
                let components = line.components(separatedBy: symbol)
                for component in components.dropFirst() {
                    let cleaned = component
                        .trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: ",", with: "")
                        .replacingOccurrences(of: " ", with: "")
                    
                    if let amount = extractNumber(from: cleaned), amount >= 0.01 {
                        amounts.append(amount)
                    }
                }
            }
        }
        
        // Also try pattern matching for comma-formatted numbers
        let currencyPattern = #"(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?)"#
        if let regex = try? NSRegularExpression(pattern: currencyPattern, options: []) {
            let nsString = line as NSString
            let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if let range = Range(match.range, in: line) {
                    let matchedString = String(line[range])
                    let cleaned = matchedString.replacingOccurrences(of: ",", with: "")
                    if let amount = Double(cleaned), amount >= 100 {
                        amounts.append(amount)
                    }
                }
            }
        }
        
        return amounts.max()
    }
    
    /// Find amount value after ₹ symbol or Rs symbol (legacy fallback)
    /// Handles formats like: ₹4,43,668.01 or Rs 443668.01 or ₹1234
    private static func findAmount(in textLines: [String]) -> Double? {
        // Multiple variations of Rupee symbol that OCR might recognize
        let rupeeSymbols = ["₹", "Rs", "Rs.", "INR", "र", "₨"]
        
        // First, try to find lines with "Bank balance" or similar keywords
        var candidateLines: [String] = []
        for line in textLines {
            let lowerLine = line.lowercased()
            if lowerLine.contains("bank balance") || lowerLine.contains("balance") || 
               lowerLine.contains("amount") || lowerLine.contains("total") {
                candidateLines.append(line)
            }
        }
        
        // If we found candidate lines, search them first
        if !candidateLines.isEmpty {
            if let amount = searchForAmount(in: candidateLines, symbols: rupeeSymbols) {
                return amount
            }
        }
        
        // Otherwise search all lines
        return searchForAmount(in: textLines, symbols: rupeeSymbols)
    }
    
    /// Search for amount in given lines with given symbols
    private static func searchForAmount(in lines: [String], symbols: [String]) -> Double? {
        var candidateAmounts: [(amount: Double, priority: Int)] = []
        
        for line in lines {
            let lowerLine = line.lowercased()
            let isBalanceLine = lowerLine.contains("bank balance") || lowerLine.contains("balance")
            
            // Try each rupee symbol variant
            for symbol in symbols {
                if line.contains(symbol) {
                    // Extract everything after the symbol
                    let components = line.components(separatedBy: symbol)
                    for component in components.dropFirst() {
                        // Clean the string: remove commas, spaces, and extract number
                        let cleaned = component
                            .trimmingCharacters(in: .whitespaces)
                            .replacingOccurrences(of: ",", with: "")
                            .replacingOccurrences(of: " ", with: "")
                        
                        // Extract numeric part (including decimal)
                        if let amount = extractNumber(from: cleaned) {
                            // Validate amount is reasonable (not too small)
                            if amount >= 0.01 {
                                // Priority: 3 for balance line, 1 for other lines
                                let priority = isBalanceLine ? 3 : 1
                                candidateAmounts.append((amount: amount, priority: priority))
                            }
                        }
                    }
                }
            }
            
            // Also try to find standalone numbers that look like currency amounts
            // Pattern: numbers with commas and optional decimal (e.g., "86,707.13")
            let currencyPattern = #"(\d{1,3}(?:,\d{2,3})*(?:\.\d{1,2})?)"#
            if let regex = try? NSRegularExpression(pattern: currencyPattern, options: []) {
                let nsString = line as NSString
                let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if let range = Range(match.range, in: line) {
                        let matchedString = String(line[range])
                        let cleaned = matchedString.replacingOccurrences(of: ",", with: "")
                        if let amount = Double(cleaned), amount >= 100 { // Minimum threshold
                            // Priority: 2 for balance line with comma-formatted number, 0 for others
                            let priority = isBalanceLine ? 2 : 0
                            candidateAmounts.append((amount: amount, priority: priority))
                        }
                    }
                }
            }
        }
        
        // Sort by priority (highest first), then by amount (largest first)
        candidateAmounts.sort { first, second in
            if first.priority != second.priority {
                return first.priority > second.priority
            }
            return first.amount > second.amount
        }
        
        // Return the highest priority amount
        return candidateAmounts.first?.amount
    }
    
    /// Extract a number from a string (handles decimals)
    private static func extractNumber(from string: String) -> Double? {
        // Pattern to match numbers with optional decimal point
        let pattern = #"^(\d+\.?\d*)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: string, options: [], range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range, in: string) else {
            return nil
        }
        
        let numberString = String(string[range])
        return Double(numberString)
    }
    
    /// Find date in various formats
    /// Supports: "7 October", "7 Oct", "07-10-2024", "as of Oct 8 2025", etc.
    private static func findDate(in textLines: [String]) -> Date? {
        let dateFormatters = createDateFormatters()
        
        for line in textLines {
            let lowerLine = line.lowercased()
            
            // Special handling for "as of" dates (common in investment screenshots)
            if lowerLine.contains("as of") {
                print("🔍 Found 'as of' in line: '\(line)'")
                // Extract the part after "as of"
                if let asOfRange = lowerLine.range(of: "as of") {
                    let afterAsOf = String(line[asOfRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    print("🔍 Text after 'as of': '\(afterAsOf)'")
                    
                    // Clean up: remove comma and time portion
                    let cleanedAfterAsOf = afterAsOf
                        .replacingOccurrences(of: ",", with: "")
                        .components(separatedBy: ",").first ?? afterAsOf
                    
                    print("🔍 Cleaned text: '\(cleanedAfterAsOf)'")
                    
                    // Try to parse this part
                    for formatter in dateFormatters {
                        let words = cleanedAfterAsOf.components(separatedBy: .whitespaces)
                        // Try different combinations
                        for i in 0..<min(words.count, 5) {
                            for length in 1...min(4, words.count - i) {
                                let dateString = words[i..<(i+length)].joined(separator: " ")
                                if let date = formatter.date(from: dateString) {
                                    print("✅ Parsed date '\(dateString)' as \(date)")
                                    return date
                                }
                            }
                        }
                    }
                    print("❌ Could not parse date from 'as of' line")
                }
            }
            
            // Try each formatter on the full line
            for formatter in dateFormatters {
                if let date = formatter.date(from: line.trimmingCharacters(in: .whitespaces)) {
                    return date
                }
                
                // Try to find date patterns within the line
                let words = line.components(separatedBy: .whitespaces)
                for i in 0..<words.count {
                    // Try single word
                    if let date = formatter.date(from: words[i]) {
                        return date
                    }
                    
                    // Try two consecutive words (e.g., "7 October")
                    if i + 1 < words.count {
                        let twoWords = "\(words[i]) \(words[i+1])"
                        if let date = formatter.date(from: twoWords) {
                            return date
                        }
                    }
                    
                    // Try three consecutive words (e.g., "7 October 2024")
                    if i + 2 < words.count {
                        let threeWords = "\(words[i]) \(words[i+1]) \(words[i+2])"
                        if let date = formatter.date(from: threeWords) {
                            return date
                        }
                    }
                    
                    // Try four consecutive words (e.g., "Oct 8 2025 09:30")
                    if i + 3 < words.count {
                        let fourWords = "\(words[i]) \(words[i+1]) \(words[i+2]) \(words[i+3])"
                        if let date = formatter.date(from: fourWords) {
                            return date
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Create array of date formatters for various date formats
    private static func createDateFormatters() -> [DateFormatter] {
        let formats = [
            "MMM d yyyy",       // Oct 8 2025 (common in investment apps)
            "MMM d, yyyy",      // Oct 8, 2025
            "d MMMM yyyy",      // 8 October 2025
            "d MMMM",           // 8 October
            "d MMM yyyy",       // 8 Oct 2025
            "d MMM",            // 8 Oct
            "dd-MM-yyyy",       // 08-10-2025
            "dd/MM/yyyy",       // 08/10/2025
            "yyyy-MM-dd",       // 2025-10-08
            "dd.MM.yyyy",       // 08.10.2025
            "MMMM d, yyyy",     // October 8, 2025
        ]
        
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current // Use user's local timezone
            // Set default year to current year for formats without year
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            formatter.defaultDate = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1))
            return formatter
        }
    }
    
    enum ParserError: LocalizedError {
        case amountNotFound
        case invalidFormat
        
        var errorDescription: String? {
            switch self {
            case .amountNotFound:
                return "Could not find amount in image. Please ensure the image shows a clear bank balance with ₹ symbol."
            case .invalidFormat:
                return "Invalid data format in image"
            }
        }
    }
}
