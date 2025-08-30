import SwiftUI

struct CreateTransactionView: View {
    let accountId: Int
    let accountBrokerId: Int // Legacy parameter name for compatibility
    var onSaved: (() -> Void)? = nil
    
    // New parameter for holdings API
    var holdingId: Int { accountBrokerId }

    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrencyCode") private var defaultCurrency: String = "INR"
    @State private var valueText: String = ""
    @State private var date: Date = Date()
    @State private var operation: Operation = .add
    @State private var saving = false
    @State private var errorMessage: String? = nil

    enum Operation: String, CaseIterable, Identifiable { case add, update; var id: String { rawValue } }

    private var valueNumber: Double? {
        let normalized = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(normalized)
    }

    private var isValid: Bool {
        valueNumber != nil
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
                        HStack(spacing: 10) {
                            Text("Amount")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 8) {
                                Text(defaultCurrency.uppercased())
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                                DecimalTextField(text: $valueText, placeholder: "0.00", fractionDigits: 2, allowNegative: true)
                                    .font(.title3.weight(.semibold))
                                    .monospacedDigit()
                                    .frame(minWidth: 120)
                                    .tint(.airbnbPrimary)
                            }
                        }
                        if let v = valueNumber {
                            let tint: Color = v >= 0 ? .airbnbSuccess : .red
                            HStack {
                                Spacer()
                                Text(v, format: .currency(code: defaultCurrency.uppercased()))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(tint)
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                            }
                            .padding(.top, 4)
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
        guard let value = valueNumber else { return }
        guard !saving else { return }
        saving = true
        errorMessage = nil
        defer { saving = false }
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let txnDate = dateFormatter.string(from: date)
            
            _ = try await RestClient().createTransaction(
                accountId: accountId,
                holdingId: holdingId,
                txnDate: txnDate,
                invested: value, // For now, assume invested = value
                value: value
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
