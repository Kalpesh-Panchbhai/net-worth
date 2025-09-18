import SwiftUI

// Reusable NamedEntity picker sheet used across the app
struct NamedEntityPickerSheet<T: NamedEntity>: View {
    let title: String
    let items: [T]
    let icon: String
    @Binding var selected: T?
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var displayed: [T] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = q.isEmpty ? items : items.filter { $0.name.localizedCaseInsensitiveContains(q) }
        // Default on top, name ascending
        return filtered.sorted { a, b in
            if a.isDefault != b.isDefault { return a.isDefault && !b.isDefault }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AppSearchBar(text: $query, placeholder: "Search")
                        .padding(.horizontal, 0)
                    SettingsGroup(showHeader: false) {
                        VStack(spacing: 0) {
                            ForEach(Array(displayed.enumerated()), id: \.element) { idx, item in
                                row(item)
                                if idx < displayed.count - 1 {
                                    Rectangle().fill(Color.subtleSeparator)
                                        .frame(height: 0.5)
                                        .padding(.horizontal, 12)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
            .background(Color.canvasBackground.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.canvasBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func row(_ item: T) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.airbnbPrimary.opacity(0.12))
                Image(systemName: (selected?.id == item.id) ? filledIcon(icon) : icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.airbnbPrimary)
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline.weight(.semibold))
                if item.isDefault { Text("Default").font(.caption2).foregroundColor(.secondary) }
            }
            Spacer()
            if selected?.id == item.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(LinearGradient.airbnbAccent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            selected = item
            Haptics.selection()
            dismiss()
        }
    }

    private func filledIcon(_ base: String) -> String {
        base.hasSuffix(".fill") ? base : base + ".fill"
    }
}
