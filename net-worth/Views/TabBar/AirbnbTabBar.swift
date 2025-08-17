import SwiftUI

struct AirbnbTabBar: View {
    @Binding var selected: AppTab
    let tabs: [AppTab]
    @Namespace private var ns
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ForEach(tabs) { tab in
                    TabButton(tab: tab, isSelected: tab == selected, ns: ns) {
                        if selected != tab { Haptics.selection() }
                        selected = tab
                    }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 0)
            .padding(.horizontal, 12)
        }
        .background(Color.elevatedBackground)
        .compositingGroup()
        .transaction { t in t.animation = nil }
        .animation(nil, value: selected)
    }
}

struct TabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let ns: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                VStack(spacing: 4) {
                    Image(systemName: tab.icon)
                        .symbolRenderingMode(.monochrome)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(isSelected ? .airbnbPrimary : .secondary)
                    Text(tab.title)
                        .font(isSelected ? .footnote.weight(.semibold) : .footnote.weight(.regular))
                        .foregroundColor(isSelected ? .airbnbPrimary : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .allowsTightening(true)
                        .opacity(isSelected ? 1.0 : 0.9)
                }
                .padding(.horizontal, 2)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}
