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
                        
                        // Recent Activity Section
                        recentActivitySection
                        
                        // Quick Actions Section
                        quickActionsSection
                        
                        // Insights Section
                        insightsSection
                        
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
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("24h Change")
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
            
            // Mini chart placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient.airbnbAccent.opacity(0.1))
                .frame(height: 60)
                .overlay {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title3)
                            .foregroundStyle(LinearGradient.airbnbAccent)
                        Text("Portfolio Performance")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }
        }
        .padding(20)
        .elevatedCardBackground(cornerRadius: 20)
    }
    
    // MARK: - Quick Stats Row
    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Accounts",
                value: "\(lookupStore.accounts.count)",
                icon: "creditcard.fill",
                color: .blue
            )
            
            StatCard(
                title: "Watchlists",
                value: "\(lookupStore.watchlists.count)",
                icon: "heart.fill",
                color: .pink
            )
            
            StatCard(
                title: "Income",
                value: monthlyIncome,
                icon: "indianrupeesign.circle.fill",
                color: .green
            )
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to activity view
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.airbnbPrimary)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(recentActivities.prefix(3), id: \.id) { activity in
                    ActivityRow(activity: activity)
                }
                
                if recentActivities.isEmpty {
                    EmptyStateCard(
                        text: "No recent activity",
                        icon: "clock",
                        iconFont: .title3
                    )
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
                    // Navigate to add account
                }
                
                QuickActionCard(
                    title: "Record Income",
                    subtitle: "Log new income",
                    icon: "plus.square.fill",
                    color: .green
                ) {
                    // Navigate to add income
                }
                
                QuickActionCard(
                    title: "Create Watchlist",
                    subtitle: "Monitor accounts",
                    icon: "heart.circle.fill",
                    color: .pink
                ) {
                    // Navigate to create watchlist
                }
                
                QuickActionCard(
                    title: "View Reports",
                    subtitle: "Analyze trends",
                    icon: "chart.bar.fill",
                    color: .orange
                ) {
                    // Navigate to reports
                }
            }
        }
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                InsightCard(
                    title: "Portfolio Diversification",
                    message: "Your portfolio is well diversified across \(lookupStore.accounts.count) accounts",
                    icon: "chart.pie.fill",
                    color: .blue
                )
                
                if let topPerformer = topPerformingAccount {
                    InsightCard(
                        title: "Top Performer",
                        message: "\(topPerformer) is your best performing account this month",
                        icon: "trophy.fill",
                        color: .yellow
                    )
                }
                
                InsightCard(
                    title: "Monthly Goal",
                    message: "You're on track to meet your savings goal this month",
                    icon: "target",
                    color: .green
                )
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
        // Mock data - implement actual calculation
        1250.50
    }
    
    private var netWorthChangePercent: String {
        let percent = (netWorthChange / totalNetWorth) * 100
        return String(format: "%.1f%%", abs(percent))
    }
    
    private var monthlyIncome: String {
        let total: Double = lookupStore.incomes.map { $0.netAmount }.reduce(0.0, +)
        return CurrencyShort.shortString(total, currency: defaultCurrency)
    }
    
    private var recentActivities: [ActivityItem] {
        // Mock data - implement actual recent activities
        []
    }
    
    private var topPerformingAccount: String? {
        lookupStore.accounts.first?.name
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
    
    var body: some View {
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

struct InsightCard: View {
    let title: String
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .elevatedCardBackground(cornerRadius: 12)
    }
}

struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.subheadline)
                .foregroundColor(activity.color)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(activity.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.elevatedBackground)
        )
    }
}

// MARK: - Data Models

struct ActivityItem {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let time: String
}
