import SwiftUI

struct CurrencyPickerSheet: View {
    @Binding var selectedCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var list: [Currency] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let base: [Currency] = q.isEmpty ? CurrencyCatalog.all : CurrencyCatalog.all.filter { c in
            c.name.localizedCaseInsensitiveContains(q)
                || c.code.localizedCaseInsensitiveContains(q)
                || c.symbol.localizedCaseInsensitiveContains(q)
        }
        let selected = selectedCode.uppercased()
        return base.sorted { a, b in
            let aSel = a.code.uppercased() == selected
            let bSel = b.code.uppercased() == selected
            if aSel != bSel { return aSel && !bSel }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    AppSearchBar(text: $query, placeholder: "Search currency")
                        .padding(.horizontal, 0)
                    SettingsGroup(title: "Currency", showHeader: false) {
                        VStack(spacing: 0) {
                            ForEach(Array(list.enumerated()), id: \.element) { idx, c in
                                row(c)
                                if idx < list.count - 1 { Hairline() }
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .padding(.bottom, LayoutConstants.tabBarHeight + 24)
            }
            .background(Color.canvasBackground.ignoresSafeArea())
            .navigationTitle("Select currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .toolbarBackground(Color.canvasBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func row(_ c: Currency) -> some View {
        Button {
            selectedCode = c.code.uppercased()
            Haptics.selection()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.airbnbPrimary.opacity(0.12))
                    Text(c.code)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.airbnbPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .frame(width: 20, height: 20)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.name).font(.subheadline.weight(.semibold))
                    Text(c.code).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if c.code.uppercased() == selectedCode.uppercased() {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.airbnbPrimary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct Hairline: View { var body: some View { Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(.horizontal, 12) } }
