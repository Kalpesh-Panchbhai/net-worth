import SwiftUI
import Charts

// MARK: - Asset Allocation View
struct AssetAllocationView: View {
    let userId: Int
    @EnvironmentObject private var lookup: LookupStore
    @AppStorage("defaultCurrencyCode") private var currency: String = "INR"
    @State private var selectedTab: AllocationTab = .accounts
    @State private var selectedAccountId: Int? = nil
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    enum AllocationTab: String, CaseIterable, Identifiable {
        case accounts = "Accounts"
        case watchlists = "Watchlists"
        case holdings = "Holdings"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .accounts: return "creditcard.fill"
            case .watchlists: return "heart.fill"
            case .holdings: return "chart.pie.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.canvasBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Tab Selector
                        tabSelector
                        
                        // Content based on selected tab
                        switch selectedTab {
                        case .accounts:
                            accountsAllocationView
                        case .watchlists:
                            watchlistsAllocationView
                        case .holdings:
                            holdingsAllocationView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Asset Allocation")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Close")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 12) {
            ForEach(AllocationTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                        if tab != .holdings {
                            selectedAccountId = nil
                        }
                    }
                    Haptics.selection()
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(selectedTab == tab ? LinearGradient.airbnbAccent : LinearGradient(colors: [Color.elevatedBackground, Color.elevatedBackground], startPoint: .top, endPoint: .bottom))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(selectedTab == tab ? .white : .secondary)
                        }
                        
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }
    
    // MARK: - Accounts Allocation
    private var accountsAllocationView: some View {
        VStack(spacing: 16) {
            if lookup.accounts.isEmpty {
                emptyStatePlaceholder(
                    icon: "creditcard.fill",
                    title: "No Accounts",
                    message: "Add accounts to see allocation"
                )
            } else {
                let chartData = accountsChartData
                let total = chartData.reduce(0.0) { $0 + $1.value }
                
                // Header
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TOTAL NET WORTH")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .tracking(1.0)
                            
                            Text(total, format: .currency(code: currency))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                                .monospacedDigit()
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Decorative icon
                        ZStack {
                            Circle()
                                .fill(LinearGradient.airbnbAccent.opacity(0.1))
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(LinearGradient.airbnbAccent)
                        }
                    }
                    .padding(20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.elevatedBackground)
                )
                .elevatedShadow()
                
                // Pie Chart
                pieChart(data: chartData, total: total)
                
                // Legend
                allocationLegend(data: chartData, total: total)
            }
        }
    }
    
    // MARK: - Watchlists Allocation
    private var watchlistsAllocationView: some View {
        VStack(spacing: 16) {
            if lookup.watchlists.isEmpty {
                emptyStatePlaceholder(
                    icon: "heart.fill",
                    title: "No Watchlists",
                    message: "Create watchlists to see allocation"
                )
            } else {
                let chartData = watchlistsChartData
                let total = chartData.reduce(0.0) { $0 + $1.value }
                
                if chartData.isEmpty {
                    emptyStatePlaceholder(
                        icon: "heart.fill",
                        title: "No Watchlists",
                        message: "Create watchlists to see allocation"
                    )
                } else {
                    // Pie Chart
                    pieChart(data: chartData, total: total)
                    
                    // Legend
                    allocationLegend(data: chartData, total: total)
                }
            }
        }
    }
    
    // MARK: - Holdings Allocation
    private var holdingsAllocationView: some View {
        VStack(spacing: 16) {
            // Account Picker
            if !lookup.accounts.isEmpty {
                accountPicker
            }
            
            if let accountId = selectedAccountId {
                holdingsAllocationForAccount(accountId: accountId)
            } else {
                emptyStatePlaceholder(
                    icon: "chart.pie.fill",
                    title: "Select an Account",
                    message: "Choose an account to view holdings allocation"
                )
            }
        }
    }
    
    private var accountPicker: some View {
        Menu {
            ForEach(lookup.accounts.filter { $0.type.lowercased() == "broker" }) { account in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedAccountId = account.id
                    }
                    Haptics.selection()
                } label: {
                    HStack {
                        Text(account.name)
                        if selectedAccountId == account.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.airbnbPrimary)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.airbnbAccent.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LinearGradient.airbnbAccent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected Account")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(selectedAccountName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.elevatedBackground)
            )
            .elevatedShadow()
        }
    }
    
    private var selectedAccountName: String {
        guard let accountId = selectedAccountId else { return "Select Broker Account" }
        return lookup.accounts.first { $0.id == accountId }?.name ?? "Select Broker Account"
    }
    
    @ViewBuilder
    private func holdingsAllocationForAccount(accountId: Int) -> some View {
        let account = lookup.accounts.first { $0.id == accountId }
        
        if let account = account {
            HoldingsAllocationContent(account: account, currency: currency)
        } else {
            emptyStatePlaceholder(
                icon: "exclamationmark.triangle",
                title: "Account Not Found",
                message: "The selected account could not be loaded"
            )
        }
    }
    
    // MARK: - Pie Chart
    private func pieChart(data: [AllocationData], total: Double) -> some View {
        Chart(data) { item in
            SectorMark(
                angle: .value("Value", item.value),
                innerRadius: .ratio(0.618),
                angularInset: 2.0
            )
            .foregroundStyle(by: .value("Name", item.name))
            .cornerRadius(5)
        }
        .chartLegend(.hidden)
        .chartForegroundStyleScale(domain: data.map { $0.name }, range: chartColors)
        .frame(height: 320)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }
    
    // MARK: - Legend
    private func allocationLegend(data: [AllocationData], total: Double) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("BREAKDOWN")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                
                Spacer()
                
                Text("\(data.count) \(data.count == 1 ? "ITEM" : "ITEMS")")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            .padding(.horizontal, 20)
            
            // Legend items
            VStack(spacing: 0) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    let percentage = total > 0 ? (item.value / total) * 100 : 0
                    
                    HStack(spacing: 0) {
                        // Color indicator with breathing room
                        Circle()
                            .fill(chartColors[index % chartColors.count])
                            .frame(width: 12, height: 12)
                            .padding(.trailing, 14)
                        
                        // Name section - takes available space
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Text("\(percentage, specifier: "%.1f")%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Value - right aligned
                        Text(item.value, format: .currency(code: currency))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(Color.elevatedBackground)
                    .contentShape(Rectangle())
                    
                    // Divider between items (except last)
                    if index < data.count - 1 {
                        Divider()
                            .padding(.leading, 46)
                            .background(Color.elevatedBackground)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Data Preparation
    private var accountsChartData: [AllocationData] {
        lookup.accounts
            .filter { $0.currentDayValue > 0 }
            .map { AllocationData(id: $0.id, name: $0.name, value: $0.currentDayValue) }
            .sorted { $0.value > $1.value }
    }
    
    private var watchlistsChartData: [AllocationData] {
        lookup.watchlists
            .filter { $0.currentDayValue > 0 && $0.name.lowercased() != "all" }
            .map { AllocationData(id: $0.id, name: $0.name, value: $0.currentDayValue) }
            .sorted { $0.value > $1.value }
    }
    
    // MARK: - Empty State Placeholder
    @ViewBuilder
    private func emptyStatePlaceholder(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(LinearGradient.airbnbAccent)
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.primary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Chart Colors
    private var chartColors: [Color] {
        [
            Color.blue,
            Color.green,
            Color.orange,
            Color.purple,
            Color.pink,
            Color.red,
            Color.yellow,
            Color.cyan,
            Color.mint,
            Color.indigo,
            Color.teal,
            Color.brown
        ]
    }
}

// MARK: - Holdings Allocation Content
struct HoldingsAllocationContent: View {
    let account: AccountSummary
    let currency: String
    @State private var holdings: [HoldingSummary] = []
    @State private var isLoading = false
    @State private var error: String? = nil
    @EnvironmentObject private var banners: BannerCenter
    @State private var loadedAccountId: Int? = nil
    
    var body: some View {
        VStack {
            if isLoading && holdings.isEmpty {
                ProgressView("Loading holdings...")
                    .padding(40)
            } else if let error = error {
                emptyStatePlaceholder(
                    icon: "exclamationmark.triangle",
                    title: "Error",
                    message: error
                )
            } else if holdings.isEmpty {
                emptyStatePlaceholder(
                    icon: "chart.pie.fill",
                    title: "No Holdings",
                    message: "Add holdings to this account to see allocation"
                )
            } else {
                let chartData = holdingsChartData
                let total = chartData.reduce(0.0) { $0 + $1.value }
                
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(account.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.airbnbPrimary)
                                
                                Text("TOTAL HOLDINGS VALUE")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.0)
                                
                                Text(total, format: .currency(code: currency))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                                    .monospacedDigit()
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Decorative icon
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "chart.pie.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(20)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.elevatedBackground)
                    )
                    .elevatedShadow()
                    
                    // Pie Chart
                    pieChart(data: chartData, total: total)
                    
                    // Legend
                    holdingsLegend(data: chartData, total: total)
                }
            }
        }
        .onAppear {
            Task {
                await loadHoldings()
            }
        }
        .onChange(of: account.id) { _, newId in
            Task {
                await loadHoldings()
            }
        }
    }
    
    private func loadHoldings() async {
        // Skip if already loaded for this account
        if loadedAccountId == account.id && !holdings.isEmpty {
            return
        }
        
        isLoading = true
        error = nil
        holdings = [] // Clear previous holdings
        defer { isLoading = false }
        
        do {
            holdings = try await RestClient().fetchHoldings(accountId: account.id)
            loadedAccountId = account.id
        } catch {
            self.error = (error as NSError).localizedDescription
            banners.showError(message: "Failed to load holdings")
        }
    }
    
    private var holdingsChartData: [AllocationData] {
        holdings
            .filter { $0.currentDayValue > 0 }
            .map { AllocationData(id: $0.id, name: $0.name, value: $0.currentDayValue) }
            .sorted { $0.value > $1.value }
    }
    
    private func pieChart(data: [AllocationData], total: Double) -> some View {
        Chart(data) { item in
            SectorMark(
                angle: .value("Value", item.value),
                innerRadius: .ratio(0.618),
                angularInset: 2.0
            )
            .foregroundStyle(by: .value("Name", item.name))
            .cornerRadius(5)
        }
        .chartLegend(.hidden)
        .chartForegroundStyleScale(domain: data.map { $0.name }, range: chartColors)
        .frame(height: 320)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }
    
    private func holdingsLegend(data: [AllocationData], total: Double) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("HOLDINGS BREAKDOWN")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                
                Spacer()
                
                Text("\(data.count) \(data.count == 1 ? "HOLDING" : "HOLDINGS")")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            .padding(.horizontal, 20)
            
            // Legend items
            VStack(spacing: 0) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    let percentage = total > 0 ? (item.value / total) * 100 : 0
                    let holding = holdings.first { $0.id == item.id }
                    
                    HStack(spacing: 0) {
                        // Color indicator with breathing room
                        Circle()
                            .fill(chartColors[index % chartColors.count])
                            .frame(width: 12, height: 12)
                            .padding(.trailing, 14)
                        
                        // Name section - takes available space
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            if let holding = holding {
                                Text("\(holding.units, specifier: "%.2f") units • \(percentage, specifier: "%.1f")%")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Value - right aligned
                        Text(item.value, format: .currency(code: currency))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(Color.elevatedBackground)
                    .contentShape(Rectangle())
                    
                    // Divider between items (except last)
                    if index < data.count - 1 {
                        Divider()
                            .padding(.leading, 46)
                            .background(Color.elevatedBackground)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var chartColors: [Color] {
        [
            Color.blue,
            Color.green,
            Color.orange,
            Color.purple,
            Color.pink,
            Color.red,
            Color.yellow,
            Color.cyan,
            Color.mint,
            Color.indigo,
            Color.teal,
            Color.brown
        ]
    }
    
    // MARK: - Empty State Placeholder
    @ViewBuilder
    private func emptyStatePlaceholder(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(LinearGradient.airbnbAccent)
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.primary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Allocation Data Model
struct AllocationData: Identifiable, Hashable {
    let id: Int
    let name: String
    let value: Double
}
