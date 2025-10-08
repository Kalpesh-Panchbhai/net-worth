import UIKit
import SwiftUI

/// Service to process screenshots and create transactions
@MainActor
class ScreenshotTransactionService: ObservableObject {
    
    @Published var isProcessing = false
    @Published var lastResult: ProcessingResult?
    
    struct ProcessingResult {
        let success: Bool
        let message: String
        let extractedData: ScreenshotOCRService.ExtractedData?
    }
    
    private let ocrService = ScreenshotOCRService()
    
    /// Process screenshot and create transaction
    func processScreenshot(_ image: UIImage, for accountName: String, userId: Int) async -> ProcessingResult {
        guard !isProcessing else {
            return ProcessingResult(success: false, message: "Already processing", extractedData: nil)
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        print("📸 Processing screenshot for account: \(accountName)")
        
        // Extract data using OCR
        let extractedData: ScreenshotOCRService.ExtractedData
        do {
            extractedData = try await ocrService.extractData(from: image)
        } catch {
            print("❌ OCR failed: \(error.localizedDescription)")
            return ProcessingResult(
                success: false,
                message: "Could not read screenshot: \(error.localizedDescription)",
                extractedData: nil
            )
        }
        
        // Validate extracted data
        guard let currentValue = extractedData.currentValue else {
            print("❌ No current value found")
            return ProcessingResult(
                success: false,
                message: "Could not find Current Value in screenshot",
                extractedData: extractedData
            )
        }
        
        let investedAmount = extractedData.investedAmount ?? currentValue
        
        print("✅ Extracted: Current=\(currentValue), Invested=\(investedAmount)")
        
        // Find matching account
        guard let account = await findAccount(byName: accountName, userId: userId) else {
            print("❌ Account not found: \(accountName)")
            return ProcessingResult(
                success: false,
                message: "Account '\(accountName)' not found",
                extractedData: extractedData
            )
        }
        
        print("✅ Found account: \(account.name) (ID: \(account.id))")
        
        // Get holding ID
        guard let holdingId = await getHoldingId(accountId: account.id) else {
            print("❌ No holding found")
            return ProcessingResult(
                success: false,
                message: "No holding found for account",
                extractedData: extractedData
            )
        }
        
        // Create transaction
        let txDate = extractedData.date ?? Date()
        let result = await createTransaction(
            accountId: account.id,
            holdingId: holdingId,
            currentValue: currentValue,
            investedAmount: investedAmount,
            date: txDate
        )
        
        if result.success {
            print("✅ Transaction created successfully")
            let message = "Transaction created\nCurrent: ₹\(formatAmount(currentValue))\nInvested: ₹\(formatAmount(investedAmount))"
            return ProcessingResult(success: true, message: message, extractedData: extractedData)
        } else {
            print("❌ Failed to create transaction: \(result.message)")
            return ProcessingResult(success: false, message: result.message, extractedData: extractedData)
        }
    }
    
    // MARK: - Helper Methods
    
    private func findAccount(byName name: String, userId: Int) async -> AccountSummary? {
        do {
            let accounts = try await RestClient().fetchAccounts(userId: userId)
            
            // Exact match first
            if let exact = accounts.first(where: { $0.name.lowercased() == name.lowercased() }) {
                return exact
            }
            
            // Partial match
            return accounts.first { account in
                account.name.lowercased().contains(name.lowercased()) ||
                name.lowercased().contains(account.name.lowercased())
            }
        } catch {
            print("❌ Error fetching accounts: \(error)")
            return nil
        }
    }
    
    private func getHoldingId(accountId: Int) async -> Int? {
        do {
            let holdings = try await RestClient().fetchHoldings(accountId: accountId)
            return holdings.first?.id
        } catch {
            print("❌ Error fetching holdings: \(error)")
            return nil
        }
    }
    
    private func createTransaction(
        accountId: Int,
        holdingId: Int,
        currentValue: Double,
        investedAmount: Double,
        date: Date
    ) async -> (success: Bool, message: String) {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let txnDate = dateFormatter.string(from: date)
            
            print("📝 Creating transaction: account=\(accountId), holding=\(holdingId)")
            print("   Value=\(currentValue), Invested=\(investedAmount), Date=\(txnDate)")
            
            _ = try await RestClient().createTransaction(
                accountId: accountId,
                holdingId: holdingId,
                txnDate: txnDate,
                invested: investedAmount,
                value: currentValue,
                mode: "update"
            )
            
            return (true, "Success")
        } catch let api as APIError {
            if case .apiError(_, let server) = api, !server.message.isEmpty {
                return (false, server.message)
            }
            return (false, api.errorDescription ?? "Failed to create transaction")
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
}
