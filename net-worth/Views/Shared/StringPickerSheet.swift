import SwiftUI

struct StringPickerSheet: View {
    let title: String
    let items: [String]
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SettingsGroup(showHeader: false) {
                        VStack(spacing: 0) {
                            ForEach(items, id: \.self) { item in
                                Button {
                                    selected = item
                                    Haptics.selection()
                                    dismiss()
                                } label: {
                                    SettingsCell(icon: "square.grid.2x2", title: item) {
                                        if selected == item {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(LinearGradient.airbnbAccent)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                if item != items.last {
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .toolbarBackground(Color.canvasBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
