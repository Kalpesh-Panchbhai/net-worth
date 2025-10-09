import SwiftUI
import PhotosUI

struct QuickImageTransactionView: View {
    let userId: Int
    var onSaved: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var banners: BannerCenter
    @EnvironmentObject private var lookupStore: LookupStore
    @AppStorage("defaultCurrencyCode") private var defaultCurrency: String = "INR"
    
    // Account selection
    @State private var selectedAccount: AccountSummary?
    @State private var showAccountPicker = false
    
    // Image picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // Extracted data
    @State private var extractedAmount: Double?
    @State private var extractedDate: Date?
    @State private var isProcessing = false
    @State private var processingError: String?
    
    // Manual editing
    @State private var amountText: String = ""
    @State private var investedText: String = ""
    @State private var date: Date = Date()
    @State private var operation: Operation = .update
    
    // Saving
    @State private var saving = false
    @State private var resolvedHoldingId: Int?
    
    enum Operation: String, CaseIterable, Identifiable {
        case add, update
        var id: String { rawValue }
    }
    
    // Filter non-broker accounts
    private var nonBrokerAccounts: [AccountSummary] {
        lookupStore.accounts.filter { account in
            let type = account.type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !(type == "broker" || type.contains("broker"))
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    private var isValid: Bool {
        guard selectedAccount != nil else { return false }
        guard let amount = Double(amountText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let invested = Double(investedText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return false
        }
        return amount > 0 && invested > 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Account selection
                SettingsGroup(title: "Select Account") {
                    VStack(spacing: 0) {
                        if nonBrokerAccounts.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("No non-broker accounts available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                        } else {
                            Button {
                                showAccountPicker = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        if let account = selectedAccount {
                                            Text(account.name)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            Text(normalizedType(account.type))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Select an account")
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Image picker section
                SettingsGroup(title: "Upload Image") {
                    VStack(spacing: 12) {
                        if let image = selectedImage {
                            // Show selected image
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.subtleSeparator, lineWidth: 1)
                                )
                        } else {
                            // Placeholder
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("Select a image")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.canvasBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.subtleSeparator, lineWidth: 1)
                            )
                        }
                        
                        // Photo picker button
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack {
                                Image(systemName: selectedImage == nil ? "photo.on.rectangle" : "arrow.triangle.2.circlepath")
                                Text(selectedImage == nil ? "Choose Image" : "Change Image")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.airbnbPrimary.opacity(0.1))
                            )
                            .foregroundColor(.airbnbPrimary)
                        }
                        .buttonStyle(.plain)
                        
                        if isProcessing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Reading image...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        if let error = processingError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                // Preview extracted data
                if extractedAmount != nil || extractedDate != nil {
                    SettingsGroup(title: "Extracted Data") {
                        VStack(spacing: 0) {
                            if let amount = extractedAmount {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.airbnbSuccess)
                                    Text("Amount")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(amount, format: .currency(code: defaultCurrency))
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.primary)
                                        .monospacedDigit()
                                }
                                .padding(.vertical, 8)
                            }
                            
                            // Show Invested if different from Amount (investment screenshots)
                            if let amount = extractedAmount,
                               let invested = Double(investedText),
                               abs(amount - invested) > 0.01 {
                                Rectangle().fill(Color.subtleSeparator)
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 12)
                                
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.airbnbSuccess)
                                    Text("Invested")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(invested, format: .currency(code: defaultCurrency))
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.primary)
                                        .monospacedDigit()
                                }
                                .padding(.vertical, 8)
                            }
                            
                            if extractedAmount != nil && extractedDate != nil {
                                Rectangle().fill(Color.subtleSeparator)
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 12)
                            }
                            
                            if let date = extractedDate {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.airbnbSuccess)
                                    Text("Date")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(date, style: .date)
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                
                // Transaction details
                if extractedAmount != nil {
                    SettingsGroup(title: "Transaction Details") {
                        VStack(spacing: 0) {
                            // Operation
                            HStack(spacing: 12) {
                                Text("Operation")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Picker("Operation", selection: $operation) {
                                    ForEach(Operation.allCases) { op in
                                        Text(op.rawValue.capitalized).tag(op)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 240)
                            }
                            .padding(.horizontal, 4)
                            
                            Rectangle().fill(Color.subtleSeparator)
                                .frame(height: 0.5)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            
                            // Amount (editable)
                            HStack(spacing: 10) {
                                Text("Amount")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 8) {
                                    Text(defaultCurrency.uppercased())
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    DecimalTextField(
                                        text: $amountText,
                                        placeholder: "0.00",
                                        fractionDigits: 2,
                                        allowNegative: false
                                    )
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                                    .frame(minWidth: 120)
                                    .tint(.airbnbPrimary)
                                }
                            }
                            
                            Rectangle().fill(Color.subtleSeparator)
                                .frame(height: 0.5)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            
                            // Invested (editable)
                            HStack(spacing: 10) {
                                Text("Invested")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 8) {
                                    Text(defaultCurrency.uppercased())
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    DecimalTextField(
                                        text: $investedText,
                                        placeholder: "0.00",
                                        fractionDigits: 2,
                                        allowNegative: false
                                    )
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                                    .frame(minWidth: 120)
                                    .tint(.airbnbPrimary)
                                }
                            }
                            
                            Rectangle().fill(Color.subtleSeparator)
                                .frame(height: 0.5)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            
                            // Date (read-only, always today)
                            HStack(spacing: 10) {
                                Text("Date")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(date, style: .date)
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, LayoutConstants.tabBarHeight + 24)
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle("Add transaction from Image")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(saving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .disabled(!isValid || saving || extractedAmount == nil)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                await loadImage()
            }
        }
        .onChange(of: selectedAccount) { oldValue, newValue in
            Task {
                await resolveHoldingIfNeeded()
            }
        }
        .task {
            // Load accounts if needed
            await lookupStore.loadIfNeeded(userId: userId)
        }
        .sheet(isPresented: $showAccountPicker) {
            accountPickerSheet
        }
    }
    
    // MARK: - Account Picker Sheet
    private var accountPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(nonBrokerAccounts) { account in
                    Button {
                        selectedAccount = account
                        showAccountPicker = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text(normalizedType(account.type))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedAccount?.id == account.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.airbnbPrimary)
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAccountPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Load and Process Image
    @MainActor
    private func loadImage() async {
        guard let item = selectedItem else { return }
        
        isProcessing = true
        processingError = nil
        extractedAmount = nil
        extractedDate = nil
        amountText = ""
        investedText = ""
        
        do {
            // Load image data
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw ImageError.loadFailed
            }
            
            selectedImage = image
            
            // Extract text from image
            let textLines = try await ImageTextExtractor.extractText(from: image)
            
            // Parse transaction details
            let parsed = try ImageTransactionParser.parse(from: textLines)
            
            // Update state
            extractedAmount = parsed.amount
            extractedDate = parsed.date
            amountText = String(format: "%.2f", parsed.amount)
            // Use invested from parser if available, otherwise same as amount
            investedText = String(format: "%.2f", parsed.invested ?? parsed.amount)
            date = parsed.date
            
            isProcessing = false
            
        } catch let error as ImageTransactionParser.ParserError {
            processingError = error.localizedDescription
            isProcessing = false
        } catch let error as ImageTextExtractor.ExtractionError {
            processingError = error.localizedDescription
            isProcessing = false
        } catch {
            processingError = "Failed to process image: \(error.localizedDescription)"
            isProcessing = false
        }
    }
    
    // MARK: - Save Transaction
    @MainActor
    private func save() async {
        guard !saving else { return }
        guard let account = selectedAccount else { return }
        guard let amount = Double(amountText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let invested = Double(investedText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }
        
        saving = true
        defer { saving = false }
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let txnDate = dateFormatter.string(from: date)
            
            // Use the values from the text fields
            let value = amount
            let investedValue = invested
            
            // Determine target holding id
            guard let targetHoldingId = resolvedHoldingId, targetHoldingId > 0 else {
                banners.showError(message: "No holding found for this account.")
                dismiss()
                return
            }
            
            _ = try await RestClient().createTransaction(
                accountId: account.id,
                holdingId: targetHoldingId,
                txnDate: txnDate,
                invested: investedValue,
                value: value,
                mode: operation.rawValue
            )
            
            banners.show(AppBanner(
                icon: "checkmark.circle.fill",
                title: "Transaction added",
                message: "Successfully added transaction from image",
                style: .success
            ))
            
            onSaved?()
            dismiss()
            
        } catch let api as APIError {
            if case .apiError(_, let server) = api, !server.message.isEmpty {
                banners.showError(message: server.message)
            } else {
                banners.showError(message: api.errorDescription ?? "Failed to save transaction")
            }
            dismiss()
        } catch {
            banners.showError(message: error.localizedDescription)
            dismiss()
        }
    }
    
    // MARK: - Resolve holding for non-broker accounts
    private func resolveHoldingIfNeeded() async {
        guard let account = selectedAccount else {
            resolvedHoldingId = nil
            return
        }
        
        do {
            let holdings = try await RestClient().fetchHoldings(accountId: account.id)
            await MainActor.run {
                self.resolvedHoldingId = holdings.first?.id
                if self.resolvedHoldingId == nil {
                    banners.showError(message: "No holding found for this account.")
                }
            }
        } catch let api as APIError {
            await MainActor.run {
                banners.showError(message: api.errorDescription ?? "Failed to load holdings")
            }
        } catch {
            await MainActor.run {
                banners.showError(message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func normalizedType(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        if t == "broker" || t.contains("broker") { return "Broker" }
        if t == "savings" || t.contains("saving") { return "Savings" }
        if t == "credit_card" || t.contains("credit") { return "Credit Card" }
        if t == "loan" || t.contains("loan") { return "Loan" }
        return "Other"
    }
    
    enum ImageError: LocalizedError {
        case loadFailed
        
        var errorDescription: String? {
            switch self {
            case .loadFailed:
                return "Failed to load image"
            }
        }
    }
}
