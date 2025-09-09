import SwiftUI
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

struct HomeView: View {
    let userId: Int
    @EnvironmentObject private var lookupStore: LookupStore
    @State private var navCollapsed = false
    @State private var refreshing = false
    @EnvironmentObject private var tabCommands: TabCommandCenter
    // Profile state
    @State private var profileName: String = ""
    @State private var profilePhotoURL: URL? = nil
    // Reports modal state
    @State private var showReportsModal = false
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    GeometryReader { proxy in
                        Color.clear.preference(key: NavBarOffsetKey.self, value: proxy.frame(in: .named("homeScroll")).minY)
                    }
                    .frame(height: 0)
                    
                    LazyVStack(spacing: 20) {
                        // Welcome Header
                        welcomeHeader
                        
                        // Net Worth Summary Card
                        netWorthSummaryCard
                        
                        // Quick Stats Row
                        quickStatsRow
                        
                        // Quick Actions Section
                        quickActionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, LayoutConstants.tabBarHeight + 24)
                    
                    Color.clear.frame(height: LayoutConstants.tabBarHeight + 24).id("homeBottom")
                }
                .background(Color.canvasBackground)
                .coordinateSpace(name: "homeScroll")
                .refreshable {
                    await refreshData()
                }
                .onChange(of: tabCommands.scrollToBottomRequest) { _, req in
                    guard req == .home else { return }
                    withAnimation(.easeInOut(duration: 0.35)) { 
                        proxy.scrollTo("homeBottom", anchor: .bottom) 
                    }
                    DispatchQueue.main.async { tabCommands.scrollToBottomRequest = nil }
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .airbnbNavBarBackground(collapsed: navCollapsed)
            .onPreferenceChange(NavBarOffsetKey.self) { y in
                withAnimation(.easeInOut(duration: 0.2)) { 
                    navCollapsed = y < -8 
                }
            }
        }
        .fullScreenCover(isPresented: $showReportsModal) {
            NavigationStack {
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        Color.canvasBackground.ignoresSafeArea()
                        AssetOverviewCard()
                            .padding(.horizontal)
                            .padding(.top)
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    }
                }
                .navigationTitle("Reports")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") { showReportsModal = false }
                    }
                }
                .toolbarBackground(Color.canvasBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
        .onAppear {
            Task {
                await loadInitialData()
            }
            fetchIdentity()
        }
    }

    // MARK: - Profile helpers
    private var firstNameDisplay: String {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let first = trimmed.split(separator: " ").first.map(String.init) ?? trimmed
        return ", \(first)"
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            Circle().fill(Color.elevatedBackground)
            if let url = profilePhotoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().scaleEffect(0.7)
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "person.fill").foregroundColor(.secondary)
                    @unknown default:
                        Image(systemName: "person.fill").foregroundColor(.secondary)
                    }
                }
            } else {
                Image(systemName: "person.fill").foregroundColor(.secondary)
            }
        }
        .frame(width: 34, height: 34)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(LinearGradient.airbnbAccent, lineWidth: 1.5).opacity(0.8)
        )
        .contentShape(Circle())
        .onTapGesture {
            Haptics.selection()
            tabCommands.navigateToTab = .settings
        }
    }

    private func fetchIdentity() {
        #if canImport(GoogleSignIn)
        if let user = GIDSignIn.sharedInstance.currentUser {
            profileName = user.profile?.name ?? profileName
            if let imageURL = user.profile?.imageURL(withDimension: 160) { profilePhotoURL = imageURL }
            return
        }
        #endif
        #if canImport(FirebaseAuth)
        if let user = Auth.auth().currentUser {
            profileName = user.displayName ?? profileName
            if let url = user.photoURL { profilePhotoURL = url }
            return
        }
        #endif
    }
    
    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(timeOfDayGreeting)")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("Welcome back\(firstNameDisplay)")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .allowsTightening(true)
            }
            
            Spacer()
            
            // Profile avatar quick access
            avatarView
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Net Worth Summary Card
    private var netWorthSummaryCard: some View {
        VStack(spacing: 16) {
            if lookupStore.isLoadingAccounts && lookupStore.accounts.isEmpty {
                // Shimmer placeholder for net worth card
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        ShimmerBlock(width: 120, height: 16, cornerRadius: 4)
                        ShimmerBlock(width: 200, height: 28, cornerRadius: 6)
                        ShimmerBlock(width: 150, height: 20, cornerRadius: 10)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        ShimmerBlock(width: 80, height: 12, cornerRadius: 4)
                        ShimmerBlock(width: 60, height: 20, cornerRadius: 4)
                    }
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Net Worth")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(totalNetWorth, format: .currency(code: defaultCurrency))
                            .font(.title.bold())
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        
                        // Savings rate capsule
                        HStack(spacing: 4) {
                            Text("\(savingsPercentage, specifier: "%.1f")% saved")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.airbnbSuccess)
                            Text("•")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.airbnbSuccess)
                            Text(netWorthChangePercent)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(netWorthChange >= 0 ? .airbnbSuccess : .airbnbPrimary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule().fill(Color.airbnbSuccess.opacity(0.12))
                        )
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("1 day change")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: netWorthChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption.bold())
                            Text(netWorthChangePercent)
                                .font(.subheadline.bold())
                                .monospacedDigit()
                        }
                        .foregroundColor(netWorthChange >= 0 ? .airbnbSuccess : .airbnbPrimary)
                    }
                }
            }
        }
        .padding(20)
        .elevatedCardBackground(cornerRadius: 20)
    }
    
    // MARK: - Quick Stats Row
    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            if lookupStore.isLoadingAccounts && lookupStore.accounts.isEmpty {
                StatCard.placeholder(title: "Accounts", icon: "creditcard.fill", color: .blue)
            } else {
                StatCard(
                    title: "Accounts",
                    value: "\(lookupStore.accounts.count)",
                    icon: "creditcard.fill",
                    color: .blue
                ) {
                    Haptics.selection()
                    tabCommands.navigateToTab = .accounts
                }
            }
            
            if lookupStore.isLoadingWatchlists && lookupStore.watchlists.isEmpty {
                StatCard.placeholder(title: "Watchlists", icon: "heart.fill", color: .pink)
            } else {
                StatCard(
                    title: "Watchlists",
                    value: "\(lookupStore.watchlists.count)",
                    icon: "heart.fill",
                    color: .pink
                ) {
                    Haptics.selection()
                    tabCommands.navigateToTab = .watchlist
                }
            }
            
            if lookupStore.isLoadingIncomes && lookupStore.incomes.isEmpty {
                StatCard.placeholder(title: "Income", icon: "indianrupeesign.circle.fill", color: .green)
            } else {
                StatCard(
                    title: "Income",
                    value: monthlyIncome,
                    icon: "indianrupeesign.circle.fill",
                    color: .green
                ) {
                    Haptics.selection()
                    tabCommands.navigateToTab = .income
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Add Account",
                    subtitle: "Track new assets",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    Haptics.selection()
                    tabCommands.presentCreate = nil
                    tabCommands.navigateToTab = .accounts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                        tabCommands.presentCreate = .accounts
                    }
                }
                
                QuickActionCard(
                    title: "Record Income",
                    subtitle: "Log new income",
                    icon: "plus.square.fill",
                    color: .green
                ) {
                    Haptics.selection()
                    tabCommands.presentCreate = nil
                    tabCommands.navigateToTab = .income
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                        tabCommands.presentCreate = .income
                    }
                }
                
                QuickActionCard(
                    title: "Create Watchlist",
                    subtitle: "Monitor accounts",
                    icon: "heart.circle.fill",
                    color: .pink
                ) {
                    Haptics.selection()
                    tabCommands.presentCreate = nil
                    tabCommands.navigateToTab = .watchlist
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                        tabCommands.presentCreate = .watchlist
                    }
                }
                
                QuickActionCard(
                    title: "View Reports",
                    subtitle: "Analyze trends",
                    icon: "chart.bar.fill",
                    color: .orange
                ) {
                    Haptics.selection()
                    showReportsModal = true
                }
            }
        }
    }
    
    
    // MARK: - Helper Properties
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }
    
    private var defaultCurrency: String {
        // Use AppStorage for default currency
        UserDefaults.standard.string(forKey: "defaultCurrencyCode") ?? "USD"
    }
    
    private var totalNetWorth: Double {
        // Calculate from lookup store
        lookupStore.accounts.reduce(0.0) { sum, account in
            sum + account.currentDayValue
        }
    }
    
    private var netWorthChange: Double {
        // Calculate actual 1-day change from account summaries
        lookupStore.accounts.reduce(0.0) { sum, account in
            sum + (account.currentDayValue - account.previousDayValue)
        }
    }
    
    private var savingsPercentage: Double {
        let totalIncome = lookupStore.incomes.reduce(0.0) { $0 + $1.netAmount }
        guard totalIncome > 0 else { return 0 }
        return (totalNetWorth / totalIncome) * 100
    }
    
    private var netWorthChangePercent: String {
        let percent = (netWorthChange / totalNetWorth) * 100
        return String(format: "%.1f%%", abs(percent))
    }
    
    private var monthlyIncome: String {
        let total: Double = lookupStore.incomes.map { $0.netAmount }.reduce(0.0, +)
        return CurrencyShort.shortString(total, currency: defaultCurrency)
    }
    
    // MARK: - Data Loading
    private func loadInitialData() async {
        // Load all data once using centralized store
        await lookupStore.loadIfNeeded(userId: userId)
    }
    
    private func refreshData() async {
        refreshing = true
        await loadInitialData()
        refreshing = false
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .monospacedDigit()
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .elevatedCardBackground(cornerRadius: 16)
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    // Shimmer placeholder version
    static func placeholder(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color.opacity(0.3))
            
            ShimmerBlock(width: 40, height: 20, cornerRadius: 4)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .elevatedCardBackground(cornerRadius: 16)
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .frame(height: 100)
            .elevatedCardBackground(cornerRadius: 16)
        }
        .buttonStyle(PressableButtonStyle())
    }
}


