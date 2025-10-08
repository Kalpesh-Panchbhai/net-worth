import SwiftUI
import PhotosUI

/// View for importing screenshots to create transactions
struct ScreenshotImportView: View {
    let accountName: String
    let userId: Int
    var onSuccess: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var banners: BannerCenter
    
    @StateObject private var service = ScreenshotTransactionService()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingPicker = false
    @State private var extractedData: ScreenshotOCRService.ExtractedData?
    @State private var isExtracting = false
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Label("How it works", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(.airbnbPrimary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            instructionRow(number: "1", text: "Take a screenshot of your account")
                            instructionRow(number: "2", text: "Select the screenshot below")
                            instructionRow(number: "3", text: "We'll automatically extract the values")
                            instructionRow(number: "4", text: "Review and create transaction")
                        }
                    }
                    .padding()
                    .background(Color.elevatedBackground)
                    .cornerRadius(12)
                    
                    // Image picker
                    if let image = selectedImage {
                        VStack(spacing: 16) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.subtleSeparator, lineWidth: 1)
                                )
                            
                            if isExtracting {
                                ProgressView("Extracting data...")
                                    .padding()
                            } else if let data = extractedData {
                                extractedDataView(data)
                                
                                if service.isProcessing {
                                    ProgressView("Creating transaction...")
                                        .padding()
                                } else {
                                    HStack(spacing: 12) {
                                        Button("Change Image") {
                                            selectedImage = nil
                                            extractedData = nil
                                            showingPicker = true
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button("Create Transaction") {
                                            Task { await createTransaction() }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(data.currentValue == nil)
                                    }
                                }
                            } else {
                                Button("Extract Data") {
                                    Task { await extractData() }
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 8)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("No screenshot selected")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button("Select Screenshot") {
                                showingPicker = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color.elevatedBackground)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(Color.canvasBackground.ignoresSafeArea())
            .navigationTitle("Import from Screenshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .photosPicker(isPresented: $showingPicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        extractedData = nil
                        // Auto-extract when image is selected
                        await extractData()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.airbnbPrimary))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private func extractedDataView(_ data: ScreenshotOCRService.ExtractedData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extracted Data")
                .font(.headline)
            
            if let currentValue = data.currentValue {
                dataRow(label: "Current Value", value: "₹\(formatAmount(currentValue))", icon: "indianrupeesign.circle.fill")
            }
            
            if let invested = data.investedAmount {
                dataRow(label: "Invested Amount", value: "₹\(formatAmount(invested))", icon: "chart.line.uptrend.xyaxis.circle.fill")
            }
            
            // Always show transaction date (from screenshot or today)
            let transactionDate = data.date ?? Date()
            dataRow(label: "Transaction Date", value: formatDate(transactionDate), icon: "calendar.circle.fill")
        }
        .padding()
        .background(Color.elevatedBackground)
        .cornerRadius(12)
    }
    
    private func dataRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.airbnbPrimary)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
    
    // MARK: - Actions
    
    private func extractData() async {
        guard let image = selectedImage else { return }
        guard !isExtracting else { return }
        
        isExtracting = true
        defer { isExtracting = false }
        
        do {
            let data = try await ScreenshotOCRService().extractData(from: image)
            extractedData = data
            
            if data.currentValue == nil {
                banners.showError(message: "Could not find Current Value in screenshot")
            } else {
                Haptics.softImpact()
            }
        } catch {
            banners.showError(message: "Failed to extract data: \(error.localizedDescription)")
            Haptics.softImpact()
        }
    }
    
    private func createTransaction() async {
        guard let image = selectedImage else { return }
        
        let result = await service.processScreenshot(image, for: accountName, userId: userId)
        
        if result.success {
            banners.show(AppBanner(
                icon: "checkmark.circle.fill",
                title: "Transaction Created",
                message: result.message,
                style: .success
            ))
            Haptics.success()
            onSuccess?()
            dismiss()
        } else {
            banners.showError(message: result.message)
            Haptics.softImpact()
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        // Check if it's today
        if Calendar.current.isDateInToday(date) {
            return "Today (\(formatter.string(from: date)))"
        }
        
        return formatter.string(from: date)
    }
}
