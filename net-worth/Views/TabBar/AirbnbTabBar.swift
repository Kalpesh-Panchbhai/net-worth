import SwiftUI

struct AirbnbTabBar: View {
    @Binding var selected: AppTab
    let tabs: [AppTab]
    @Namespace private var ns
    @EnvironmentObject private var tabCommands: TabCommandCenter
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    TabButton(tab: tab, isSelected: tab == selected, ns: ns) {
                        if selected != tab { Haptics.selection(); selected = tab }
                        // On any tap, request scroll-to-bottom for that tab
                        DispatchQueue.main.async { tabCommands.scrollToBottomRequest = tab }
                    }
                }
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .background(Color.elevatedBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.subtleSeparator)
                .frame(height: 0.5)
        }
        .compositingGroup()
        .ignoresSafeArea(edges: .bottom)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selected)
    }
}

struct TabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let ns: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(isSelected ? .airbnbPrimary : .secondary)
                Text(tab.title)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .airbnbPrimary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .opacity(isSelected ? 1.0 : 0.9)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

