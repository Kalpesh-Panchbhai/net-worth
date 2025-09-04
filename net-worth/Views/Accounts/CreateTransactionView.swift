import SwiftUI

struct CreateTransactionView: View {
    let accountId: Int
    let accountBrokerId: Int // Legacy parameter name for compatibility
    let needsDailyData: Bool // For non-broker accounts
    var onSaved: (() -> Void)? = nil
    
    // New parameter for holdings API
    var holdingId: Int { accountBrokerId }

    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrencyCode") private var defaultCurrency: String = "INR"
    // Inputs (conditionally used)
    @State private var amountText: String = ""     // non-broker amount OR broker units? -> we keep separate
    @State private var investedText: String = ""   // explicit invested when required
    @State private var unitsText: String = ""      // broker units
    @State private var date: Date = Date()
    @State private var operation: Operation = .add
    @State private var saving = false
    @State private var errorMessage: String? = nil

    enum Operation: String, CaseIterable, Identifiable { case add, update; var id: String { rawValue } }

    private var amountNumber: Double? {
        let normalized = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(normalized)
    }
    private var investedNumber: Double? {
        let normalized = investedText.trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(normalized)
    }
    private var unitsNumber: Double? {
        let normalized = unitsText.trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(normalized)
    }

    private var isValid: Bool {
        if holdingId > 0 {
            // Broker holding: need units and invested
            return unitsNumber != nil && investedNumber != nil
        } else {
            if needsDailyData {
                // Non-broker with daily data: amount + invested
                return amountNumber != nil && investedNumber != nil
            } else {
                // Non-broker without daily data: only amount
                return amountNumber != nil
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingsGroup(title: "Operation") {
                    HStack(spacing: 12) {
                        Text("Operation")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Operation", selection: $operation) {
                            ForEach(Operation.allCases) { op in Text(op.rawValue.capitalized).tag(op) }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 240)
                    }
                    .padding(.horizontal, 4)
                }

                SettingsGroup(title: "Details") {
                    VStack(spacing: 0) {
                        if holdingId > 0 {
                            // Broker holding: Units + Invested
                            HStack(spacing: 10) {
                                Text("Units")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                DecimalTextField(text: $unitsText, placeholder: "0.0000", fractionDigits: 6, allowNegative: false)
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                                    .frame(minWidth: 120)
                                    .tint(.airbnbPrimary)
                            }
                            Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(.horizontal, 12).padding(.vertical, 10)
                            HStack(spacing: 10) {
                                Text("Invested")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 8) {
                                    Text(defaultCurrency.uppercased())
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    DecimalTextField(text: $investedText, placeholder: "0.00", fractionDigits: 2, allowNegative: true)
                                        .font(.title3.weight(.semibold))
                                        .monospacedDigit()
                                        .frame(minWidth: 120)
                                        .tint(.airbnbPrimary)
                                }
                            }
                        } else if needsDailyData {
                            // Non-broker with daily data: Amount + Invested
                            HStack(spacing: 10) {
                                Text("Amount")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 8) {
                                    Text(defaultCurrency.uppercased())
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    DecimalTextField(text: $amountText, placeholder: "0.00", fractionDigits: 2, allowNegative: true)
                                        .font(.title3.weight(.semibold))
                                        .monospacedDigit()
                                        .frame(minWidth: 120)
                                        .tint(.airbnbPrimary)
                                }
                            }
                            Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(.horizontal, 12).padding(.vertical, 10)
                            HStack(spacing: 10) {
                                Text("Invested")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 8) {
                                    Text(defaultCurrency.uppercased())
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    DecimalTextField(text: $investedText, placeholder: "0.00", fractionDigits: 2, allowNegative: true)
                                        .font(.title3.weight(.semibold))
                                        .monospacedDigit()
                                        .frame(minWidth: 120)
                                        .tint(.airbnbPrimary)
                                }
                            }
                        } else {
                            // Non-broker without daily data: Amount only
                            HStack(spacing: 10) {
                                Text("Amount")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 8) {
                                    Text(defaultCurrency.uppercased())
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    DecimalTextField(text: $amountText, placeholder: "0.00", fractionDigits: 2, allowNegative: true)
                                        .font(.title3.weight(.semibold))
                                        .monospacedDigit()
                                        .frame(minWidth: 120)
                                        .tint(.airbnbPrimary)
                                }
                            }
                        }
                        Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(.horizontal, 12).padding(.vertical, 10)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                        }
                        .padding(.top, 6)
                    }
                }

                if let err = errorMessage, !err.isEmpty {
                    EmptyStateCard(text: err, icon: "exclamationmark.triangle", iconFont: .title3)
                }
            }
            .padding(16)
            .padding(.bottom, LayoutConstants.tabBarHeight + 24)
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle("Add transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(saving ? "Saving…" : "Save") { Task { await save() } }
                    .disabled(!isValid || saving)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    @MainActor
    private func save() async {
        guard !saving else { return }
        saving = true
        errorMessage = nil
        defer { saving = false }
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let txnDate = dateFormatter.string(from: date)
            
            // Map inputs per rules
            let invested: Double
            let value: Double
            if holdingId > 0 {
                guard let units = unitsNumber, let inv = investedNumber else { return }
                value = units
                invested = inv
            } else if needsDailyData {
                guard let amt = amountNumber, let inv = investedNumber else { return }
                value = amt
                invested = inv
            } else {
                guard let amt = amountNumber else { return }
                value = amt
                invested = amt
            }

            _ = try await RestClient().createTransaction(
                accountId: accountId,
                holdingId: holdingId,
                txnDate: txnDate,
                invested: invested,
                value: value,
                mode: operation.rawValue
            )
            onSaved?()
            dismiss()
        } catch let api as APIError {
            errorMessage = api.errorDescription ?? "Failed to save transaction"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
