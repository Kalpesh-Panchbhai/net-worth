import SwiftUI

// Generic list for any NamedEntity (e.g., IncomeType, IncomeTag)
struct NamedEntitiesListView<T: NamedEntity>: View {
    let title: String
    let userId: Int
    let regularIcon: String
    let defaultIcon: String
    let fetch: (IncomeService, Int) async throws -> [T]

    @State private var items: [T] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var query: String = ""
    private let service = IncomeService()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let err = errorMessage {
                    SettingsGroup(title: "Error") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(err)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Button(action: { Task { await load() } }) {
                                Text("Retry").bold()
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(Capsule(style: .continuous).fill(LinearGradient.airbnbAccent))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
                SettingsGroup(title: title) {
                    VStack(spacing: 0) {
                        let displayed = items.filter { query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? true : $0.name.localizedCaseInsensitiveContains(query) }
                        if isLoading && items.isEmpty {
                            ForEach(0..<6, id: \.self) { i in
                                NamedEntityRow<T>.placeholder()
                                if i != 5 { Hairline() }
                            }
                            .shimmer()
                        } else if displayed.isEmpty {
                            VStack(alignment: .center, spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text(items.isEmpty ? "No items found" : "No results for ‘\(query)’")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        } else {
                            ForEach(Array(displayed.enumerated()), id: \.element) { idx, item in
                                NamedEntityRow(entity: item, regularIcon: regularIcon, defaultIcon: defaultIcon)
                                if idx < displayed.count - 1 { Hairline() }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: Text("Search"))
        .animation(.easeInOut(duration: 0.2), value: query)
    }

    private func load() async {
        errorMessage = nil
        isLoading = true
        do {
            let fetched = try await fetch(service, userId)
            // Sort: default first, then name ascending
            items = fetched.sorted { a, b in
                if a.isDefault != b.isDefault { return a.isDefault && !b.isDefault }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}

// Row
private struct NamedEntityRow<T: NamedEntity>: View {
    let entity: T
    var regularIcon: String = "tag"
    var defaultIcon: String = "star.fill"
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.airbnbPrimary.opacity(0.10))
                Image(systemName: entity.isDefault ? defaultIcon : regularIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LinearGradient.airbnbAccent)
            }
            .frame(width: 32, height: 32)
            .overlay(Circle().stroke(Color.subtleSeparator, lineWidth: 1))
            Text(entity.name)
                .font(.body.weight(.semibold))
                .foregroundColor(.primary)
            Spacer()
            if entity.isDefault {
                Text("Default")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(LinearGradient.airbnbAccent))
                    .shadow(color: .airbnbPrimary.opacity(0.25), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(entity.name) \(entity.isDefault ? "default" : "")"))
    }
}

private struct Hairline: View { var body: some View { Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(.horizontal, 12) } }

// Generic fallback placeholder (used regardless of T)
private extension NamedEntityRow {
    static func placeholder() -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color.airbnbPrimary.opacity(0.12)).frame(width: 28, height: 28)
            RoundedRectangle(cornerRadius: 4).fill(Color.subtleSeparator).frame(width: 150, height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 12).fill(Color.subtleSeparator).frame(width: 60, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private extension NamedEntityRow where T == IncomeType {
    static func placeholder() -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color.airbnbPrimary.opacity(0.12)).frame(width: 28, height: 28)
            RoundedRectangle(cornerRadius: 4).fill(Color.subtleSeparator).frame(width: 140, height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 12).fill(Color.subtleSeparator).frame(width: 60, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private extension NamedEntityRow where T == IncomeTag {
    static func placeholder() -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color.airbnbPrimary.opacity(0.12)).frame(width: 28, height: 28)
            RoundedRectangle(cornerRadius: 4).fill(Color.subtleSeparator).frame(width: 160, height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 12).fill(Color.subtleSeparator).frame(width: 60, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
