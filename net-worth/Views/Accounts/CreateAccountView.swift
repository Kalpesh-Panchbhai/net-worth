import SwiftUI

struct CreateAccountView: View {
    let userId: Int
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lookup: LookupStore
    @EnvironmentObject private var banners: BannerCenter
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode: String = "INR"

    @State private var name: String = ""
    @State private var typeDisplay: String = "Broker"
    @State private var typeCode: String = "BROKER"
    @State private var currency: String = "INR"
    @State private var needsDailyData: Bool = true
    @State private var saving: Bool = false
    @State private var showCurrencyPicker: Bool = false
    @State private var showTypePicker: Bool = false

    private let client = RestClient()
    private let accountTypes: [(display: String, code: String)] = [
        ("Broker", "BROKER"),
        ("Savings", "SAVINGS"),
        ("Credit Card", "CREDIT_CARD"),
        ("Loan", "LOAN"),
        ("Other", "OTHER")
    ]

    init(userId: Int) {
        self.userId = userId
        _currency = State(
            initialValue: UserDefaults.standard.string(forKey: "defaultCurrencyCode")?.uppercased()
                ?? "INR")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // DETAILS GROUP: name, type, currency
                SettingsGroup(title: "Details") {
                    VStack(spacing: 0) {
                        // Name field
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                TextField("Name", text: $name)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                            }
                            Rectangle().fill(Color.subtleSeparator).frame(height: 0.5)
                        }
                        // Type (sheet)
                        Button {
                            showTypePicker = true
                            Haptics.selection()
                        } label: {
                            SettingsCell(icon: "square.grid.2x2", title: "Type", subtitle: typeDisplay) {
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(
                            .horizontal, 12)
                        // Currency (sheet)
                        Button {
                            showCurrencyPicker = true
                            Haptics.selection()
                        } label: {
                            SettingsCell(
                                title: "Currency",
                                subtitle: CurrencyCatalog.byCode[currency.uppercased()]?.name
                                    ?? currency,
                                leading: {
                                    Circle().fill(Color.airbnbPrimary.opacity(0.12))
                                        .overlay(
                                            Text(currency.uppercased())
                                                .font(.caption2.weight(.bold))
                                                .foregroundColor(.airbnbPrimary)
                                                .minimumScaleFactor(0.6)
                                                .lineLimit(1)
                                                .frame(width: 20, height: 20)
                                        )
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                }
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Needs daily data (only for non-broker types)
                        if typeCode != "BROKER" {
                            Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(
                                .horizontal, 12)
                            HStack(spacing: 12) {
                                SettingsCell(
                                    icon: "calendar.badge.clock",
                                    title: "Needs daily data",
                                    subtitle: needsDailyData ? "Yes" : "No"
                                ) {
                                    Toggle("", isOn: $needsDailyData)
                                        .labelsHidden()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Enable this if values for this account are tracked daily and you want to enter both amount and invested for transactions. Disable to enter only a single amount.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 12)
                                .padding(.top, 6)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, LayoutConstants.tabBarHeight + 24)
        }
        .background(ScrollToTopEnabler())
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle("New account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(saving ? "Saving…" : "Save") { Task { await save() } }
                    .disabled(!isValid || saving)
            }
        }
        .toolbarBackground(Color.canvasBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showCurrencyPicker) { CurrencyPickerSheet(selectedCode: $currency) }
        .sheet(isPresented: $showTypePicker) {
            AccountTypePickerSheet(
                title: "Select type",
                items: accountTypes,
                selectedDisplay: $typeDisplay,
                selectedCode: $typeCode
            )
        }
        // Keep Broker always daily-data=true, reset to false when switching to non-broker
        .onChange(of: typeCode) { _, newCode in
            if newCode == "BROKER" {
                needsDailyData = true
            } else if needsDailyData {
                // default to false when switching out of Broker
                needsDailyData = false
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        saving = true
        do {
            _ = try await client.createAccount(
                userId: userId,
                name: trimmed,
                type: typeCode,
                currency: currency.uppercased(),
                isActive: true,
                needsDailyData: (typeCode == "BROKER") ? true : needsDailyData
            )
            // POST succeeded; stop showing Saving…
            saving = false
            // Kick off refreshes in the background (don’t block UI)
            Task {
                async let a: Void = lookup.refreshAccounts(userId: userId)
                async let b: Void = lookup.refreshWatchlists(userId: userId)
                _ = await (a, b)
            }
            Haptics.success()
            dismiss()
        } catch let api as APIError {
            saving = false
            banners.showError(message: api.errorDescription ?? "Request failed")
            Haptics.softImpact()
        } catch {
            saving = false
            banners.showError(message: error.localizedDescription)
            Haptics.softImpact()
        }
    }
}

// MARK: - Type Mapping (UI display -> API enum)
private func apiTypeValue(_ display: String) -> String {
    let t = display.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    switch t {
    case "broker": return "BROKER"
    case "saving", "savings": return "SAVINGS"
    case "credit card", "credit-card", "credit_card": return "CREDIT_CARD"
    case "loan": return "LOAN"
    default: return "OTHER"
    }
}

// Local AccountTypePickerSheet removed. Using shared StringPickerSheet.
