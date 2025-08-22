import SwiftUI

struct DefaultCurrencyView: View {
    @AppStorage("defaultCurrencyCode") private var defaultCode: String = "INR"
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var list: [Currency] {
        let base: [Currency]
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            base = CurrencyCatalog.all
        } else {
            base = CurrencyCatalog.all.filter { c in
                c.name.localizedCaseInsensitiveContains(q) ||
                c.code.localizedCaseInsensitiveContains(q) ||
                c.symbol.localizedCaseInsensitiveContains(q)
            }
        }
        // Pin the default currency to the top
        let def = defaultCode.uppercased()
        return base.sorted { a, b in
            let aDef = a.code.uppercased() == def
            let bDef = b.code.uppercased() == def
            if aDef != bDef { return aDef && !bDef }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Use our custom AppSearchBar instead of .searchable
                AppSearchBar(text: $query, placeholder: "Search currency")
                    .padding(.horizontal, 0)
                SettingsGroup(title: "Default currency", showHeader: false) {
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
        .background(ScrollToTopEnabler())
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle("Default currency")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.canvasBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 66) }
    }

    @ViewBuilder
    private func row(_ c: Currency) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.airbnbPrimary.opacity(0.12))
                Text(c.code)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.airbnbPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .allowsTightening(true)
                    .frame(width: 20, height: 20, alignment: .center)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(c.name)
                    .font(.subheadline.weight(.semibold))
                Text(c.code)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if c.code.uppercased() == defaultCode.uppercased() {
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
        .contentShape(Rectangle())
        .onTapGesture {
            defaultCode = c.code
            Haptics.selection()
            dismiss()
        }
    }
}

private struct Hairline: View { var body: some View { Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(.horizontal, 12) } }
