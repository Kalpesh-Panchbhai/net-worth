import SwiftUI

// Generic list for any NamedEntity (e.g., IncomeSource, IncomeTag)
struct NamedEntitiesListView<T: NamedEntity>: View {
    let title: String
    let userId: Int
    let regularIcon: String
    let defaultIcon: String
    var useStore: Bool = false
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
    @EnvironmentObject private var lookup: LookupStore
    @EnvironmentObject private var banners: BannerCenter

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Errors are shown via the global top banner.
                SettingsGroup(title: title, showHeader: false) {
                    VStack(spacing: 0) {
                        let source: [T] = useStore ? storeItems : items
                        let displayed = source.filter { query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? true : $0.name.localizedCaseInsensitiveContains(query) }
                        let displayedSorted = displayed.sorted { a, b in
                            if a.isDefault != b.isDefault { return a.isDefault && !b.isDefault }
                            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                        }
                        if !useStore && isLoading && source.isEmpty {
                            ForEach(0..<6, id: \.self) { i in
                                NamedEntityRow<T>.placeholder()
                                if i != 5 { Hairline() }
                            }
                        } else if displayedSorted.isEmpty {
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
                            ForEach(Array(displayedSorted.enumerated()), id: \.element) { idx, item in
                                if !item.isDefault, let setDefault {
                                    NamedEntityRow<T>(entity: item, regularIcon: regularIcon, defaultIcon: defaultIcon)
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
                                if idx < displayedSorted.count - 1 { Hairline() }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .padding(
                .bottom,
                (create != nil)
                    ? (LayoutConstants.tabBarHeight + LayoutConstants.fabBottomMargin + LayoutConstants.fabSize + 24)
                    : (LayoutConstants.tabBarHeight + 24)
            )
        }
        .background(ScrollToTopEnabler())
        .refreshable {
            if useStore { await refreshStore() }
            else { await load(force: true, suppressErrors: true) }
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { if !useStore { await load() } }
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
        .fabOverlay(accessibilityLabel: "Add", isVisible: create != nil) { isShowingCreate = true }
        .onChange(of: errorMessage) { _, newValue in
            guard let message = newValue, !message.isEmpty else { return }
            // Don't show retry for duplicate errors (409) since retrying won't help
            let isDuplicateError = message.contains("already exists") || message.contains("duplicate") || message.contains("choose a different name")
            if isDuplicateError {
                banners.showError(message: message)
            } else {
                banners.showError(message: message, retryTitle: "Retry", retry: { Task { await load() } })
            }
        }
    }

    private func load(force: Bool = false, suppressErrors: Bool = false) async {
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
                // Suppress banners during pull-to-refresh if we already have data
                if !suppressErrors && items.isEmpty {
                    await MainActor.run { errorMessage = message }
                }
            }
        }
        await MainActor.run { isLoading = false }
    }

    private func markDefault(_ item: T, setDefault: @escaping (RestClient, T) async throws -> Void) async {
        await MainActor.run { patchingId = item.id }
        do {
            try await setDefault(client, item)
            Haptics.success()
            if useStore { await refreshStore() } else { await load() }
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
            if useStore {
                await refreshStore()
            } else {
                await MainActor.run {
                    items.append(created)
                    items.sort { a, b in
                        if a.isDefault != b.isDefault { return a.isDefault && !b.isDefault }
                        return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                    }
                }
            }
            await MainActor.run {
                createName = ""
                createIsDefault = false
            }
            // Give backend a tiny moment to persist for non-store mode
            try? await Task.sleep(nanoseconds: 250_000_000)
            if !useStore { await load(force: true) }
        } catch {
            let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
            await MainActor.run { errorMessage = message }
        }
        await MainActor.run { creating = false }
    }

}

private extension NamedEntitiesListView {
    var storeItems: [T] {
        if T.self == IncomeSource.self { return (lookup.incomeSources as? [T]) ?? [] }
        if T.self == IncomeTag.self { return (lookup.incomeTags as? [T]) ?? [] }
        return []
    }
    func refreshStore() async {
        if T.self == IncomeSource.self {
            await lookup.refreshIncomeSources(userId: userId)
        } else if T.self == IncomeTag.self {
            await lookup.refreshIncomeTags(userId: userId)
        }
    }
}

// FloatingPlusButton replaced by Shared/FloatingActionButton

// Row
private struct NamedEntityRow<T: NamedEntity>: View {
    let entity: T
    var regularIcon: String = "tag"
    var defaultIcon: String = "star.fill"
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.airbnbPrimary.opacity(0.12))
                Image(systemName: entity.isDefault ? defaultIcon : regularIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.airbnbPrimary)
            }
            .frame(width: 32, height: 32)
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
            ShimmerCircle(diameter: 28)
            ShimmerBlock(width: 150, height: 14, cornerRadius: 4)
            Spacer()
            ShimmerBlock(width: 60, height: 20, cornerRadius: 12)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private extension NamedEntityRow where T == IncomeSource {
    static func placeholder() -> some View {
        HStack(spacing: 12) {
            ShimmerCircle(diameter: 28)
            ShimmerBlock(width: 140, height: 14, cornerRadius: 4)
            Spacer()
            ShimmerBlock(width: 60, height: 20, cornerRadius: 12)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private extension NamedEntityRow where T == IncomeTag {
    static func placeholder() -> some View {
        HStack(spacing: 12) {
            ShimmerCircle(diameter: 28)
            ShimmerBlock(width: 160, height: 14, cornerRadius: 4)
            Spacer()
            ShimmerBlock(width: 60, height: 20, cornerRadius: 12)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

