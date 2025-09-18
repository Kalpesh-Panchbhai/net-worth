import SwiftUI

// MARK: - Reusable Income Filter Sheet
struct IncomeFilterSheet: View {
    let types: [String]
    let tags: [String]
    let years: [Int]
    let fys: [IncomeController.FinancialYear]
    @Binding var selectedTypes: Set<String>
    @Binding var selectedTags: Set<String>
    @Binding var selectedYears: Set<Int>
    @Binding var selectedFYs: Set<IncomeController.FinancialYear>
    let onDone: () -> Void
    let onClear: () -> Void
    
    @State private var query: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                AppSearchBar(text: $query, placeholder: "Search")
                    .padding(.top, 8)

                // Source (chips)
                SettingsGroup(title: sourceTitle) {
                    let filtered = types.filter {
                        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
                        return q.isEmpty ? true : $0.localizedCaseInsensitiveContains(q)
                    }
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], alignment: .leading, spacing: 8) {
                        ForEach(filtered, id: \.self) { item in
                            FilterChip(title: item, isOn: selectedTypes.contains(item)) {
                                withAnimation(.snappy) {
                                    if selectedTypes.contains(item) { selectedTypes.remove(item) }
                                    else { selectedTypes.insert(item) }
                                }
                                Haptics.selection()
                            }
                        }
                    }
                }

                // Tag (chips)
                SettingsGroup(title: tagTitle) {
                    let filtered = tags.filter {
                        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
                        return q.isEmpty ? true : $0.localizedCaseInsensitiveContains(q)
                    }
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], alignment: .leading, spacing: 8) {
                        ForEach(filtered, id: \.self) { item in
                            FilterChip(title: item, isOn: selectedTags.contains(item)) {
                                withAnimation(.snappy) {
                                    if selectedTags.contains(item) { selectedTags.remove(item) }
                                    else { selectedTags.insert(item) }
                                }
                                Haptics.selection()
                            }
                        }
                    }
                }

                // Year (list with highlight)
                SettingsGroup(title: yearTitle) {
                    let filteredYears = years.filter {
                        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
                        return q.isEmpty ? true : String($0).localizedCaseInsensitiveContains(q)
                    }.sorted(by: >)
                    VStack(spacing: 0) {
                        ForEach(filteredYears.indices, id: \.self) { idx in
                            let y = filteredYears[idx]
                            let isSel = selectedYears.contains(y)
                            Button {
                                withAnimation(.snappy) {
                                    if isSel { selectedYears.remove(y) } else { selectedYears.insert(y) }
                                }
                                Haptics.selection()
                            } label: {
                                HStack {
                                    Text(String(y))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if isSel {
                                        Image(systemName: "checkmark")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundColor(.airbnbPrimary)
                                            .padding(6)
                                            .background(Circle().fill(Color.airbnbPrimary.opacity(0.12)))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(isSel ? Color.airbnbPrimary.opacity(0.06) : .clear)
                                )
                            }
                            .buttonStyle(.plain)
                            if idx < filteredYears.count - 1 {
                                Rectangle().fill(Color.subtleSeparator).frame(height: 0.5)
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                }

                // Financial year (list with highlight)
                SettingsGroup(title: fyTitle) {
                    let filtered = fys.filter {
                        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
                        return q.isEmpty ? true : $0.title.localizedCaseInsensitiveContains(q)
                    }
                    VStack(spacing: 0) {
                        ForEach(filtered.indices, id: \.self) { idx in
                            let fy = filtered[idx]
                            let isSel = selectedFYs.contains(fy)
                            Button {
                                withAnimation(.snappy) {
                                    if isSel { selectedFYs.remove(fy) } else { selectedFYs.insert(fy) }
                                }
                                Haptics.selection()
                            } label: {
                                HStack {
                                    Text(fy.title)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if isSel {
                                        Image(systemName: "checkmark")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundColor(.airbnbPrimary)
                                            .padding(6)
                                            .background(Circle().fill(Color.airbnbPrimary.opacity(0.12)))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(isSel ? Color.airbnbPrimary.opacity(0.06) : .clear)
                                )
                            }
                            .buttonStyle(.plain)
                            if idx < filtered.count - 1 {
                                Rectangle().fill(Color.subtleSeparator).frame(height: 0.5)
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                }

                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.canvasBackground)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button(action: {
                    onClear()
                    onDone()
                }) {
                    Text("Clear filters").bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.airbnbPrimary)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.elevatedBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.subtleSeparator, lineWidth: 1)
                        )
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(16)
            .background(Color.canvasBackground.ignoresSafeArea(edges: .bottom))
        }
        .tint(.airbnbPrimary)
    }

    // MARK: - Helpers (titles and summaries)
    private var sourceTitle: String {
        selectedTypes.isEmpty ? "Source" : "Source (\(selectedTypes.count))"
    }
    private var tagTitle: String {
        selectedTags.isEmpty ? "Tag" : "Tag (\(selectedTags.count))"
    }
    private var yearTitle: String {
        selectedYears.isEmpty ? "Year" : "Year (\(selectedYears.count))"
    }
    private var fyTitle: String {
        selectedFYs.isEmpty ? "Financial year" : "Financial year (\(selectedFYs.count))"
    }

    private var sourceSummary: String? { selectionSummary(Array(selectedTypes).sorted()) }
    private var tagSummary: String? { selectionSummary(Array(selectedTags).sorted()) }
    private var yearSummary: String? { selectionSummary(Array(selectedYears).sorted(by: >).map(String.init)) }
    private var fySummary: String? { selectionSummary(selectedFYs.map { $0.title }.sorted()) }

    private func selectionSummary(_ items: [String]) -> String? {
        guard !items.isEmpty else { return nil }
        let maxShow = 3
        let shown = items.prefix(maxShow)
        let extra = items.count - shown.count
        let text = shown.joined(separator: ", ") + (extra > 0 ? "  ·  +\(extra) more" : "")
        return text
    }
}
