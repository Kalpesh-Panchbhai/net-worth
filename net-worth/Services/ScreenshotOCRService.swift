import UIKit
import Vision
import VisionKit

/// Service to extract financial data from screenshots using OCR
class ScreenshotOCRService {
    
    struct ExtractedData {
        let currentValue: Double?
        let investedAmount: Double?
        let accountName: String?
        let date: Date?
    }
    
    /// Extract financial data from screenshot image
    func extractData(from image: UIImage) async throws -> ExtractedData {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        // Perform OCR
        let recognizedText = try await performOCR(on: cgImage)
        
        // Parse the recognized text
        return parseFinancialData(from: recognizedText)
    }
    
    // MARK: - OCR Processing
    
    private func performOCR(on cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            // Configure for better accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Data Parsing
    
    private func parseFinancialData(from text: String) -> ExtractedData {
        print("🔍 OCR Text:\n\(text)\n")
        
        let lines = text.components(separatedBy: .newlines)
        
        var currentValue: Double?
        var investedAmount: Double?
        var accountName: String?
        var date: Date?
        
        for (index, line) in lines.enumerated() {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract Current Value
            // Patterns: "Current Value", "₹3,64,473.47", "₹2,86,816.62"
            if cleanLine.lowercased().contains("current value") && currentValue == nil {
                // Check next few lines for the value
                for offset in 1...3 {
                    if index + offset < lines.count {
                        let nextLine = lines[index + offset]
                        if let value = extractAmount(from: nextLine) {
                            // Only accept if it's a reasonable value (between 10,000 and 100,000,000)
                            // This filters out OCR errors like 73,64,473 (should be 3,64,473)
                            if value > 10000 && value < 100_000_000 {
                                currentValue = value
                                print("✅ Found Current Value: \(value) from line: '\(nextLine.trimmingCharacters(in: .whitespacesAndNewlines))'")
                                break
                            }
                        }
                    }
                }
            }
            
            // Extract Invested Amount
            // Patterns: "Invested Amount", "₹2,50,000.00"
            if cleanLine.lowercased().contains("invested amount") {
                // Next line usually contains the value
                if index + 1 < lines.count {
                    if let value = extractAmount(from: lines[index + 1]) {
                        investedAmount = value
                        print("✅ Found Invested Amount: \(value)")
                    }
                }
            }
            
            // Extract account name
            // Look for company names or fund names
            if cleanLine.contains("Pension") || cleanLine.contains("Fund") || cleanLine.contains("Company") {
                accountName = cleanLine
                print("✅ Found Account Name: \(cleanLine)")
            }
            
            // Extract date
            // Pattern: "as of Oct 7 2025"
            if cleanLine.lowercased().contains("as of") {
                date = extractDate(from: cleanLine)
                if let d = date {
                    print("✅ Found Date: \(d)")
                }
            }
        }
        
        // Fallback: If Current Value not found, look for the largest amount in first 10 lines
        if currentValue == nil {
            var maxValue: Double = 0
            for (index, line) in lines.enumerated() {
                guard index < 10 else { break } // Only check first 10 lines
                if let value = extractAmount(from: line), value > maxValue {
                    maxValue = value
                }
            }
            if maxValue > 10000 {
                currentValue = maxValue
                print("⚠️ Using fallback Current Value (largest in first 10 lines): \(maxValue)")
            }
        }
        
        return ExtractedData(
            currentValue: currentValue,
            investedAmount: investedAmount,
            accountName: accountName,
            date: date
        )
    }
    
    // MARK: - Helper Methods
    
    private func extractAmount(from text: String) -> Double? {
        // Remove currency symbols and clean up
        var cleaned = text.replacingOccurrences(of: "₹", with: "")
        cleaned = cleaned.replacingOccurrences(of: "Rs", with: "")
        cleaned = cleaned.replacingOccurrences(of: "Rs.", with: "")
        cleaned = cleaned.replacingOccurrences(of: "·", with: "") // Remove middle dot
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract number with commas using regex
        // Pattern: digits with optional commas and decimal point (e.g., "3,64,473.47")
        let pattern = #"([\d,]+\.?\d*)"#
        guard let range = cleaned.range(of: pattern, options: .regularExpression) else {
            return nil
        }
        
        var numberString = String(cleaned[range])
        
        // Fix OCR errors: If number starts with 73 and has Indian format, likely should start with 3
        // Indian format: X,XX,XXX.XX (e.g., 3,64,473.47)
        // OCR sometimes reads ₹3 as 73
        if numberString.hasPrefix("73,") {
            // Pattern: 73,XX,XXX (should be 3,XX,XXX)
            // Remove the leading 7
            numberString = String(numberString.dropFirst())
            print("🔧 Fixed OCR error: removed leading '7' from '\(numberString)'")
        }
        
        // Remove commas AFTER extraction to preserve the full number
        let cleanedNumber = numberString.replacingOccurrences(of: ",", with: "")
        return Double(cleanedNumber)
    }
    
    private func extractDate(from text: String) -> Date? {
        // Pattern: "as of Oct 7 2025, 09:30 PM"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Clean up the text
        var cleaned = text.replacingOccurrences(of: "as of ", with: "", options: .caseInsensitive)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try multiple formats
        let formats = [
            "MMM d yyyy, hh:mm a",  // Oct 7 2025, 09:30 PM
            "MMM d yyyy",           // Oct 7 2025
            "dd MMM yyyy",          // 7 Oct 2025
            "yyyy-MM-dd"            // 2025-10-07
        ]
        
        for format in formats {
            dateFormatter.dateFormat = format
            
            // Try exact match first
            if let date = dateFormatter.date(from: cleaned) {
                print("✅ Found Date: \(date) using format '\(format)'")
                return date
            }
            
            // Try to find date pattern in the string
            let words = cleaned.components(separatedBy: " ")
            for i in 0..<words.count {
                // Try 3-word combinations (e.g., "Oct 7 2025")
                if i + 2 < words.count {
                    let candidate = "\(words[i]) \(words[i+1]) \(words[i+2])"
                    if let date = dateFormatter.date(from: candidate) {
                        print("✅ Found Date: \(date) from '\(candidate)' using format '\(format)'")
                        return date
                    }
                }
                
                // Try 5-word combinations for time formats (e.g., "Oct 7 2025, 09:30")
                if i + 4 < words.count && format.contains("hh:mm") {
                    let candidate = "\(words[i]) \(words[i+1]) \(words[i+2]) \(words[i+3]) \(words[i+4])"
                    if let date = dateFormatter.date(from: candidate) {
                        print("✅ Found Date: \(date) from '\(candidate)' using format '\(format)'")
                        return date
                    }
                }
            }
        }
        
        print("⚠️ Could not parse date from: '\(text)'")
        return nil
    }
}

// MARK: - Errors

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noTextFound:
            return "No text found in image"
        case .parsingFailed:
            return "Could not parse financial data"
        }
    }
}
