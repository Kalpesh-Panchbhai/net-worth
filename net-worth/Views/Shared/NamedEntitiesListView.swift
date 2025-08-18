import SwiftUI

// Generic list for any NamedEntity (e.g., IncomeType, IncomeTag)
struct NamedEntitiesListView<T: NamedEntity>: View {
    let title: String
    let userId: Int
    let regularIcon: String
    let defaultIcon: String
    let fetch: (RestClient, Int) async throws -> [T]
    let setDefault: ((RestClient, T) async throws -> Void)?
    let create: ((RestClient, Int, String, Bool) async throws -> T)?

    @State private var items: [T] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var query: String = ""
    @State private var patchingId: Int? = nil
    @State private var isShowingCreate: Bool = false
    @State private var createName: String = ""
    @State private var createIsDefault: Bool = false
    @State private var creating: Bool = false
    private let client = RestClient()
    @EnvironmentObject private var banners: BannerCenter

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Errors are shown via the global top banner.
                SettingsGroup(title: title, showHeader: false) {
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
                                if !item.isDefault, let setDefault {
                                    NamedEntityRow(entity: item, regularIcon: regularIcon, defaultIcon: defaultIcon)
                                        .contentShape(Rectangle())
                                        .contextMenu {
                                            Button(action: { Task { await markDefault(item, setDefault: setDefault) } }) { Text("Set default") }
                                        }
                                        .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 10, pressing: { isPressing in
                                            if isPressing { Haptics.softImpact() }
                                        }, perform: {
                                            Task { await markDefault(item, setDefault: setDefault) }
                                        })
                                        .disabled(patchingId != nil)
                                } else {
                                    NamedEntityRow(entity: item, regularIcon: regularIcon, defaultIcon: defaultIcon)
                                        .contentShape(Rectangle())
                                }
                                if idx < displayed.count - 1 { Hairline() }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .refreshable { await load(force: true) }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .toolbarBackground(Color.canvasBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isShowingCreate) {
            ZStack {
                Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 16) {
                            SettingsGroup(showHeader: false) {
                                VStack(alignment: .leading, spacing: 12) {
                                    TextField("Name", text: $createName)
                                        .textInputAutocapitalization(.words)
                                        .disableAutocorrection(true)
                                    Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(.horizontal, 0)
                                    Toggle("Set as default", isOn: $createIsDefault)
                                        .tint(.airbnbPrimary)
                                }
                                .padding(.horizontal, 4)
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                        .background(Color.clear)
                    }
                    .navigationTitle("New")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isShowingCreate = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(creating ? "Saving…" : "Save") { Task { await createItem() } }
                                .disabled(createName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || creating)
                        }
                    }
                    .toolbarBackground(Color.canvasBackground, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                }
            }
            .presentationDetents([.height(220), .medium, .large])
            .interactiveDismissDisabled(creating)
            .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .bottomTrailing) {
            if create != nil {
                FloatingPlusButton { isShowingCreate = true }
                    .padding(.trailing, 16)
                    .padding(.bottom, 96)
            }
        }
        .onChange(of: errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            banners.showError(message: message, retryTitle: "Retry", retry: { Task { await load() } })
        }
    }

    private func load(force: Bool = false) async {
        if isLoading && !force { return }
        await MainActor.run {
            errorMessage = nil
            isLoading = true
        }
        do {
            let fetched = try await fetch(client, userId)
            // Sort: default first, then name ascending
            let sorted = fetched.sorted { a, b in
                if a.isDefault != b.isDefault { return a.isDefault && !b.isDefault }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            await MainActor.run {
                items = sorted
                errorMessage = nil
            }
        } catch is CancellationError {
            // Ignore refresh/task cancellation
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                // ignore
            } else {
                let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
                await MainActor.run { errorMessage = message }
            }
        }
        await MainActor.run { isLoading = false }
    }

    private func markDefault(_ item: T, setDefault: @escaping (RestClient, T) async throws -> Void) async {
        await MainActor.run { patchingId = item.id }
        do {
            try await setDefault(client, item)
            Haptics.success()
            await load()
        } catch {
            let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
            await MainActor.run { errorMessage = message }
        }
        await MainActor.run { patchingId = nil }
    }

    private func createItem() async {
        guard let create else { return }
        // Snapshot values and close the sheet immediately for better UX
        let name = createName.trimmingCharacters(in: .whitespacesAndNewlines)
        let isDef = createIsDefault
        await MainActor.run {
            isShowingCreate = false
            errorMessage = nil
        }
        do {
            let created = try await create(client, userId, name, isDef)
            Haptics.success()
            // Optimistic local update
            await MainActor.run {
                items.append(created)
                items.sort { a, b in
                    if a.isDefault != b.isDefault { return a.isDefault && !b.isDefault }
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
            }
            await MainActor.run {
                createName = ""
                createIsDefault = false
            }
            // Give backend a tiny moment to persist, then reload
            try? await Task.sleep(nanoseconds: 250_000_000)
            await load(force: true)
        } catch {
            let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
            await MainActor.run { errorMessage = message }
        }
        await MainActor.run { creating = false }
    }

}

// MARK: - Floating + Button
private struct FloatingPlusButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(LinearGradient.airbnbAccent))
                .shadow(color: .airbnbPrimary.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.94))
        .accessibilityLabel("Add")
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
            RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(width: 150, height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 12).fill(Color.placeholderFill).frame(width: 60, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private extension NamedEntityRow where T == IncomeType {
    static func placeholder() -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color.airbnbPrimary.opacity(0.12)).frame(width: 28, height: 28)
            RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(width: 140, height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 12).fill(Color.placeholderFill).frame(width: 60, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private extension NamedEntityRow where T == IncomeTag {
    static func placeholder() -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color.airbnbPrimary.opacity(0.12)).frame(width: 28, height: 28)
            RoundedRectangle(cornerRadius: 4).fill(Color.placeholderFill).frame(width: 160, height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 12).fill(Color.placeholderFill).frame(width: 60, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

