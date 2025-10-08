import SwiftUI

struct AccountDetailView: View {
    let account: AccountSummary
    @AppStorage("defaultCurrencyCode") private var displayCurrency: String = "INR"
    @EnvironmentObject private var lookup: LookupStore
    @EnvironmentObject private var banners: BannerCenter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var brokerHoldings: [AccountBroker] = []
    @State private var isLoadingBroker = false
    @State private var brokerError: String? = nil
    @State private var transactions: [AccountTransaction] = []
    @State private var isLoadingTx = false
    @State private var txError: String? = nil
    @State private var showCreateTx = false
    // Watchlists containing this account
    @State private var accountWatchlists: [WatchlistSummary] = []
    @State private var isLoadingWatches = false
    @State private var watchesError: String? = nil
    // Simplified transactions UI (no filters/search/summary)
    @State private var showEditSheet = false
    @State private var editName: String = ""
    @State private var editActive: Bool = true
    // Optimistic UI states
    @State private var displayName: String = ""
    @State private var displayIsActive: Bool = true
    @State private var didBootstrapDisplay = false
    @State private var savingEdits: Bool = false
    // Add Holding (broker only)
    @State private var showAddHoldingSheet = false
    @State private var holdingSearch: String = ""
    @State private var isSearchingHolding = false
    @State private var holdingResults: [YahooFinanceClient.Quote] = []
    @State private var selectedHoldingId: Int = 0
    @State private var showDeleteHoldingAlert = false
    @State private var deleteHoldingTarget: (id: Int, name: String)? = nil
    @State private var showFabMenu = false
    // Add to Watchlist
    @State private var showAddToWatchSheet = false
    @State private var addingWatchlistId: Int? = nil
    @State private var removingWatchlistId: Int? = nil
    @State private var showReportsModal = false
    // Screenshot import
    @State private var showScreenshotImport = false
    // Micro-interactions for toolbar button
    @State private var breathe = false
    @State private var rippleTrigger = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary for this account
                let total = account.currentDayValue
                let invested = account.invested
                let previous = account.previousDayValue
                let changeVsPrev = total - previous
                let changePercent: Double? =
                    abs(previous) > 0 ? (changeVsPrev / abs(previous)) : nil

                AccountsSummaryCard(
                    total: total,
                    invested: invested,
                    changeVsPrev: changeVsPrev,
                    changePercent: changePercent,
                    currency: displayCurrency.uppercased()
                )

                // Account details
                SettingsGroup(title: "Account") {
                    VStack(spacing: 0) {
                        detailRow(icon: "person.crop.circle", title: "Name", subtitle: displayName)
                        divider()
                        detailRow(
                            icon: "square.grid.2x2", title: "Type",
                            subtitle: normalizedType(account.type))
                        divider()
                        detailRow(
                            icon: "coloncurrencysign.circle",
                            title: "Account currency",
                            subtitle: CurrencyCatalog.byCode[account.currency.uppercased()]?.name
                                ?? account.currency.uppercased(),
                            trailing: {
                                Text(account.currency.uppercased())
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                        )
                        // Only for non-broker accounts, show needs daily data
                        if normalizedType(account.type) != "Broker" {
                            divider()
                            detailRow(
                                icon: "calendar.badge.clock",
                                title: "Enabled daily data",
                                subtitle: account.needsDailyData ? "Yes" : "No"
                            )
                        }
                        divider()
                        detailRow(
                            icon: displayIsActive ? "checkmark.seal" : "xmark.seal",
                            title: "Status",
                            subtitle: displayIsActive ? "Active" : "Inactive"
                        )
                    }
                }
                

                // Transactions (non-broker) — with watchlists shown above
                if normalizedType(account.type) != "Broker" {
                    // Show watchlists above transactions for non-broker accounts
                    watchlistsSection()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Showing last 5 transactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        if isLoadingTx && transactions.isEmpty {
                            ForEach(0..<5, id: \.self) { _ in transactionPlaceholderRow() }
                        } else if let err = txError {
                            VStack(spacing: 10) {
                                EmptyStateCard(
                                    text: err, icon: "exclamationmark.triangle", iconFont: .title3)
                                Button(action: { Task { await loadTransactions() } }) {
                                    Label("Retry", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else if transactions.isEmpty {
                            EmptyStateCard(
                                text: "No transactions yet", icon: "tray", iconFont: .title3)
                        } else {
                            let sortedAll = sortedTransactions(transactions)
                            let preview = Array(sortedAll.prefix(5))
                            VStack(spacing: 12) {
                                ForEach(preview.indices, id: \.self) { i in
                                    let tx = preview[i]
                                    let prevVal: Double? =
                                        (i + 1 < sortedAll.count) ? sortedAll[i + 1].value : nil
                                    let prevInvested: Double? =
                                        (i + 1 < sortedAll.count) ? sortedAll[i + 1].invested : nil
                                    transactionRowView(
                                        date: DateTZ.fromBackendISTStringToUserDate(
                                            tx.transactionDate) ?? Date(),
                                        value: tx.value,
                                        previousValue: prevVal,
                                        operation: tx.operation,
                                        currency: displayCurrency.uppercased(),
                                        invested: tx.invested,
                                        previousInvested: prevInvested
                                    )
                                }
                            }
                        }
                    }
                }

                // Broker holdings
                if normalizedType(account.type) == "Broker" {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Holdings")
                            .font(.caption).bold()
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        if isLoadingBroker && brokerHoldings.isEmpty {
                            ForEach(0..<5, id: \.self) { _ in AssetRowCard.placeholder() }
                        } else if let err = brokerError {
                            VStack(spacing: 10) {
                                EmptyStateCard(
                                    text: err, icon: "exclamationmark.triangle", iconFont: .title3)
                                Button(action: { Task { await loadBroker() } }) {
                                    Label("Retry", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else if brokerHoldings.isEmpty {
                            EmptyStateCard(text: "No holdings yet", icon: "tray", iconFont: .title3)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(brokerHoldings, id: \.id) { h in
                                    NavigationLink(value: h) {
                                        AssetRowCard(
                                            name: h.name.isEmpty ? h.symbol : h.name,
                                            current: h.value.currentValue,
                                            invested: h.value.invested,
                                            previous: h.value.previousValue,
                                            currency: displayCurrency.uppercased(),
                                            units: h.currentUnit
                                        )
                                    }
                                    .contextMenu {
                                        if displayIsActive {
                                            Button {
                                                selectedHoldingId = h.id
                                                showCreateTx = true
                                            } label: {
                                                Label("Add Transaction", systemImage: "plus.circle")
                                            }
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            deleteHoldingTarget = (id: h.id, name: h.name.isEmpty ? h.symbol : h.name)
                                            showDeleteHoldingAlert = true
                                        } label: {
                                            Label("Delete Holding", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // In watchlists (for broker accounts, keep below holdings)
                if normalizedType(account.type) == "Broker" {
                    watchlistsSection()
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, LayoutConstants.tabBarHeight + 24)
        }
        .background(Color.canvasBackground.ignoresSafeArea())
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { trendToolbarButton }
        }
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .fabOverlay(
            icon: showFabMenu ? "xmark" : "plus",
            accessibilityLabel: "Actions",
            isVisible: true
        ) {
            if reduceMotion {
                showFabMenu.toggle()
            } else {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    showFabMenu.toggle()
                }
            }
            Haptics.selection()
        }
        // Tap-catcher to dismiss menu when tapping outside
        .overlay {
            if showFabMenu {
                Color.black.opacity(0.001) // invisible catch layer
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { showFabMenu = false }
                    }
            }
        }
        // Multi-option FAB menu (Airbnb-style, circular buttons)
        .overlay(alignment: .bottomTrailing) { fabMenu }
        .navigationDestination(for: AccountBroker.self) { holding in
            BrokerHoldingDetailView(holding: holding, isAccountActive: displayIsActive)
        }
        .navigationDestination(for: WatchlistSummary.self) { item in
            WatchlistAccountsView(userId: account.userId, watchlist: item)
        }
        .sheet(isPresented: $showCreateTx) {
            NavigationStack {
                CreateTransactionView(
                    accountId: account.id,
                    holdingId: selectedHoldingId,
                    needsDailyData: account.needsDailyData,
                    onSaved: { 
                        Task { 
                            if normalizedType(account.type) == "Broker" {
                                await loadBroker()
                            } else {
                                await loadTransactions()
                            }
                        }
                    }
                )
            }
        }
        .onChange(of: showCreateTx) { oldValue, newValue in
            // When the sheet is dismissed, force a refresh to avoid any race with onSaved
            if oldValue == true && newValue == false {
                Task {
                    if normalizedType(account.type) == "Broker" {
                        await loadBroker()
                    } else {
                        await loadTransactions()
                    }
                    // Reset any previously selected holding id
                    selectedHoldingId = 0
                }
            }
        }
        .task {
            await loadBroker()
            await loadTransactions()
            await loadAccountWatches()
        }
        .sheet(isPresented: $showEditSheet) { editSheet }
        .sheet(isPresented: $showAddHoldingSheet) { addHoldingSheet }
        .sheet(isPresented: $showAddToWatchSheet) { addToWatchSheet }
        .sheet(isPresented: $showScreenshotImport) {
            ScreenshotImportView(
                accountName: account.name,
                userId: account.userId,
                onSuccess: {
                    Task {
                        await loadTransactions()
                        await lookup.refreshAccounts(userId: account.userId)
                    }
                }
            )
        }
        .alert("Delete holding?", isPresented: $showDeleteHoldingAlert, presenting: deleteHoldingTarget) { target in
            Button("Delete", role: .destructive) {
                Task { await deleteHolding(id: target.id, name: target.name) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { target in
            Text("This will permanently delete \(target.name) from this account.")
        }
        // Close FAB menu when leaving screen
        .onDisappear { showFabMenu = false }
        .fullScreenCover(isPresented: $showReportsModal) {
            NavigationStack {
                GeometryReader { geo in
                    ZStack(alignment: .top) {
                        Color.canvasBackground.ignoresSafeArea()
                        AssetOverviewCard(
                            preselect: (
                                type: .account,
                                id: account.id,
                                name: account.name
                            )
                        )
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
            if !didBootstrapDisplay {
                displayName = account.name
                displayIsActive = account.isActive
                didBootstrapDisplay = true
            }
        }
    }

    // MARK: - Toolbar Button
    private var trendToolbarButton: some View {
        Button {
            Haptics.selection()
            showReportsModal = true
            // Tap ripple feedback (respect Reduce Motion)
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) { rippleTrigger.toggle() }
            // Reset ripple after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { withAnimation(.easeOut(duration: 0.25)) { rippleTrigger = false } }
        } label: {
            ZStack {
                // Soft radial glow behind the button
                Circle()
                    .fill(Color.airbnbPrimary.opacity(0.22))
                    .blur(radius: 10)
                    .scaleEffect(breathe ? 1.08 : 0.96)
                    .opacity(0.8)

                Circle()
                    .fill(LinearGradient.airbnbAccent)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                    )
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .padding(1)
                            .opacity(0.7)
                    )

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                // Ripple ring
                Circle()
                    .stroke(LinearGradient.airbnbAccent, lineWidth: 2)
                    .scaleEffect(rippleTrigger ? 1.7 : 0.9)
                    .opacity(rippleTrigger ? 0.35 : 0.0)
                    .animation(.easeOut(duration: 0.6), value: rippleTrigger)
            }
            .frame(width: 34, height: 34)
            .scaleEffect(reduceMotion ? 1.0 : (breathe ? 1.02 : 0.98))
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathe)
            .onAppear { if !reduceMotion { breathe = true } }
        }
        .buttonStyle(PressableButtonStyle(scale: 0.96))
        .accessibilityLabel("View Trends")
    }

    // MARK: - Delete Holding
    @MainActor
    private func deleteHolding(id: Int, name: String) async {
        do {
            try await RestClient().deleteHolding(id: id)
            await loadBroker()
            banners.show(AppBanner(icon: "trash", title: "Holding deleted", message: name, style: .success))
        } catch let api as APIError {
            banners.showError(message: api.errorDescription ?? "Failed to delete holding")
        } catch {
            banners.showError(message: error.localizedDescription)
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private func detailRow<Trailing: View>(
        icon: String, title: String, subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        SettingsCell(icon: icon, title: title, subtitle: subtitle) {
            trailing()
        }
    }

    @ViewBuilder
    private func divider() -> some View {
        Rectangle().fill(Color.subtleSeparator)
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }

    private func normalizedType(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        if t == "broker" || t.contains("broker") { return "Broker" }
        if t == "savings" || t.contains("saving") { return "Savings" }
        if t == "credit_card" || t.contains("credit") { return "Credit Card" }
        if t == "loan" || t.contains("loan") { return "Loan" }
        return "Other"
    }

    // MARK: - Mini FAB helper
    @ViewBuilder
    private func miniFab(label: String, icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundColor(enabled ? .primary : .secondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    Capsule().fill(Color.elevatedBackground)
                )
                .overlay(
                    Capsule().stroke(Color.subtleSeparator, lineWidth: 1)
                )
            Button(action: {
                if enabled { Haptics.selection(); action() } else { Haptics.softImpact() }
            }) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(enabled ? LinearGradient.airbnbAccent : LinearGradient(colors: [.secondary.opacity(0.4), .secondary.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
            }
            .buttonStyle(PressableButtonStyle(scale: 0.94))
            .disabled(!enabled)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - FAB Menu (extracted for readability and compiler performance)
    private var fabMenu: some View {
        Group {
            if showFabMenu {
                let isBroker = normalizedType(account.type) == "Broker"
                let addLabel = isBroker ? "Add holding" : "Add transaction"
                let canAdd = displayIsActive
                VStack(alignment: .trailing, spacing: 14) {
                    if canAdd {
                        miniFab(label: addLabel, icon: "plus", enabled: true) {
                            if reduceMotion { showFabMenu = false }
                            else { withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { showFabMenu = false } }
                            if isBroker { showAddHoldingSheet = true } else { showCreateTx = true }
                        }
                        .offset(y: showFabMenu ? 0 : 18)
                        .scaleEffect(showFabMenu ? 1.0 : 0.92)
                        .opacity(showFabMenu ? 1.0 : 0.0)
                        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85), value: showFabMenu)
                    }
                    // Screenshot import (non-broker only)
                    if !isBroker && canAdd {
                        miniFab(label: "Add transaction from screenshot", icon: "photo", enabled: true) {
                            if reduceMotion { showFabMenu = false }
                            else { withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { showFabMenu = false } }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { showScreenshotImport = true }
                        }
                        .offset(y: showFabMenu ? 0 : 22)
                        .scaleEffect(showFabMenu ? 1.0 : 0.92)
                        .opacity(showFabMenu ? 1.0 : 0.0)
                        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85).delay(0.04), value: showFabMenu)
                    }
                    miniFab(label: "Add to watchlist", icon: "text.badge.plus", enabled: true) {
                        if reduceMotion { showFabMenu = false } else {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { showFabMenu = false }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { showAddToWatchSheet = true }
                    }
                    .offset(y: showFabMenu ? 0 : (canAdd && !isBroker ? 26 : canAdd ? 22 : 18))
                    .scaleEffect(showFabMenu ? 1.0 : 0.92)
                    .opacity(showFabMenu ? 1.0 : 0.0)
                    .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85).delay(canAdd && !isBroker ? 0.08 : canAdd ? 0.04 : 0), value: showFabMenu)
                    miniFab(label: "Edit", icon: "pencil", enabled: true) {
                        if reduceMotion { showFabMenu = false }
                        else { withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) { showFabMenu = false } }
                        editName = displayName
                        editActive = displayIsActive
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { showEditSheet = true }
                    }
                    .offset(y: showFabMenu ? 0 : (canAdd && !isBroker ? 30 : canAdd ? 26 : 18))
                    .scaleEffect(showFabMenu ? 1.0 : (canAdd ? 0.9 : 0.92))
                    .opacity(showFabMenu ? 1.0 : 0.0)
                    .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.85).delay(canAdd && !isBroker ? 0.12 : canAdd ? 0.08 : 0.03), value: showFabMenu)
                }
                .padding(.trailing, LayoutConstants.fabTrailing)
                .padding(.bottom, LayoutConstants.tabBarHeight + LayoutConstants.fabBottomMargin + LayoutConstants.fabSize + 10)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Edit Sheet (PATCH name / isActive)
    private var editSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                SettingsGroup(title: "Edit account") {
                    VStack(spacing: 0) {
                        // Name
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                TextField("Name", text: $editName)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(true)
                            }
                            Rectangle().fill(Color.subtleSeparator).frame(height: 0.5)
                        }
                        // Active / Inactive
                        let canDeactivate = (account.currentDayValue == 0 && account.invested == 0)
                        Rectangle().fill(Color.subtleSeparator).frame(height: 0.5).padding(.horizontal, 12)
                        HStack(spacing: 12) {
                            SettingsCell(
                                icon: "checkmark.seal",
                                title: "Status",
                                subtitle: editActive ? "Active" : "Inactive"
                            ) {
                                Toggle("", isOn: $editActive)
                                    .labelsHidden()
                                    .disabled(!canDeactivate && !editActive) // cannot switch off unless allowed
                            }
                        }
                        if !canDeactivate {
                            Text("You can mark this account Inactive only when Total and Invested are both 0.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.top, 6)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.canvasBackground.ignoresSafeArea())
            .navigationTitle("Edit account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showEditSheet = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(savingEdits ? "Saving…" : "Save") { Task { await saveEdits() } }
                        .disabled(savingEdits || editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .toolbarBackground(Color.canvasBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @MainActor
    private func saveEdits() async {
        let trimmed = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Only allow inactivation when both totals are 0
        let canDeactivate = (account.currentDayValue == 0 && account.invested == 0)
        var isActiveParam: Bool? = nil
        if editActive != account.isActive {
            if editActive == false && !canDeactivate {
                // enforce rule; keep active
                isActiveParam = true
            } else {
                isActiveParam = editActive
            }
        }
        let nameParam: String? = (trimmed == account.name) ? nil : trimmed
        savingEdits = true
        do {
            _ = try await RestClient().updateAccount(id: account.id, name: nameParam, isActive: isActiveParam)
            // Optimistic UI update
            displayName = trimmed
            if let newActive = isActiveParam { displayIsActive = newActive }
            // Refresh lists in background
            Task {
                async let a: Void = lookup.refreshAccounts(userId: account.userId)
                async let b: Void = lookup.refreshWatchlists(userId: account.userId)
                _ = await (a, b)
            }
            banners.show(AppBanner(icon: "checkmark.circle.fill", title: "Account updated", message: nil, style: .success))
            showEditSheet = false
        } catch let api as APIError {
            banners.showError(message: api.errorDescription ?? "Failed to update account")
        } catch {
            banners.showError(message: error.localizedDescription)
        }
        savingEdits = false
    }

    @MainActor
    private func loadBroker() async {
        // Only for broker accounts, avoid duplicate loads
        guard normalizedType(account.type) == "Broker" else { return }
        if isLoadingBroker { return }
        isLoadingBroker = true
        brokerError = nil
        defer { isLoadingBroker = false }
        // Load from LookupStore cache-first
        await lookup.loadHoldingsIfNeeded(accountId: account.id)
        if let cached = lookup.getHoldings(for: account.id) {
            self.brokerHoldings = cached.sorted { a, b in
                let an = a.name.isEmpty ? a.symbol : a.name
                let bn = b.name.isEmpty ? b.symbol : b.name
                return an.localizedCaseInsensitiveCompare(bn) == .orderedAscending
            }
        } else {
            brokerError = "Failed to load holdings from cache"
        }
    }

    @MainActor
    private func loadTransactions() async {
        // Only for non-broker accounts
        guard normalizedType(account.type) != "Broker" else { return }
        if isLoadingTx { return }
        isLoadingTx = true
        txError = nil
        defer { isLoadingTx = false }
        do {
            let list = try await RestClient().fetchLegacyAccountTransactions(accountId: account.id)
            self.transactions = list
        } catch let api as APIError {
            txError = api.errorDescription ?? "Failed to load transactions"
        } catch {
            txError = error.localizedDescription
        }
    }

    @MainActor
    private func loadAccountWatches() async {
        if isLoadingWatches { return }
        isLoadingWatches = true
        watchesError = nil
        defer { isLoadingWatches = false }
        do {
            let links = try await RestClient().fetchAccountWatchlists(accountId: account.id)
            self.accountWatchlists = links.sorted { a, b in
                let aIsAll =
                    a.name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    .localizedCaseInsensitiveCompare("All") == .orderedSame
                let bIsAll =
                    b.name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    .localizedCaseInsensitiveCompare("All") == .orderedSame
                if aIsAll != bIsAll { return aIsAll && !bIsAll }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
        } catch let api as APIError {
            watchesError = api.errorDescription ?? "Failed to load watchlists"
        } catch {
            watchesError = error.localizedDescription
        }
    }

    private func sortedTransactions(_ arr: [AccountTransaction]) -> [AccountTransaction] {
        arr.sorted { a, b in
            let da = DateTZ.fromBackendISTStringToUserDate(a.transactionDate) ?? .distantPast
            let db = DateTZ.fromBackendISTStringToUserDate(b.transactionDate) ?? .distantPast
            return da > db  // newest first
        }
    }

    // MARK: - Watchlists section (reusable)
    @ViewBuilder
    private func watchlistsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In watchlists")
                .font(.caption).bold()
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            if isLoadingWatches && accountWatchlists.isEmpty {
                ForEach(0..<3, id: \.self) { _ in AssetRowCard.placeholder() }
            } else if let err = watchesError {
                EmptyStateCard(text: err, icon: "exclamationmark.triangle", iconFont: .title3)
            } else if accountWatchlists.isEmpty {
                EmptyStateCard(text: "Not in any watchlist", icon: "eye.slash", iconFont: .title3)
            } else {
                VStack(spacing: 12) {
                    ForEach(accountWatchlists, id: \.id) { wl in
                        NavigationLink(value: wl) {
                            AssetRowCard(
                                name: wl.name,
                                current: wl.currentDayValue,
                                invested: wl.invested,
                                previous: wl.previousDayValue,
                                currency: displayCurrency.uppercased()
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Add Holding Sheet (Broker accounts)
    private var addHoldingSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section with search
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.airbnbPrimary)
                            Text("Find your stock")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.primary)
                            Text("Search by company name or symbol")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Modern search bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16, weight: .medium))
                            TextField("e.g., Apple, AAPL", text: $holdingSearch)
                                .textInputAutocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 16))
                                .onSubmit { Task { await searchHoldings() } }
                            if isSearchingHolding {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(holdingSearch.isEmpty ? Color.clear : Color.airbnbPrimary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Results section
                    if !holdingResults.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Search Results")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(holdingResults.count) found")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color(.systemGray5)))
                            }
                            
                            LazyVStack(spacing: 0) {
                                ForEach(holdingResults, id: \.symbol) { item in
                                    Button {
                                        Task { await createHolding(from: item) }
                                    } label: {
                                        HStack(spacing: 12) {
                                            // Stock icon
                                            ZStack {
                                                Circle()
                                                    .fill(Color.airbnbPrimary.opacity(0.1))
                                                    .frame(width: 44, height: 44)
                                                Text(String(item.symbol.prefix(2)))
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.airbnbPrimary)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.longname ?? item.shortname ?? item.symbol)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                
                                                HStack(spacing: 8) {
                                                    Text(item.symbol)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(.airbnbPrimary)
                                                    
                                                    if let exchange = item.exchDisp, !exchange.isEmpty {
                                                        Text("•")
                                                            .foregroundColor(.secondary)
                                                            .font(.caption)
                                                        Text(exchange)
                                                            .font(.caption.weight(.medium))
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.airbnbPrimary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemBackground))
                                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } else if !holdingSearch.isEmpty && !isSearchingHolding {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No results found")
                                .font(.headline.weight(.medium))
                                .foregroundColor(.primary)
                            Text("Try searching with a different company name or stock symbol")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    } else if holdingSearch.isEmpty {
                        // Initial state
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("Start typing to search")
                                .font(.headline.weight(.medium))
                                .foregroundColor(.primary)
                            Text("Popular: AAPL, GOOGL, MSFT, TSLA")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Add Holding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showAddHoldingSheet = false }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.airbnbPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task(id: holdingSearch) { await searchHoldings() }
    }

    // MARK: - Add To Watchlist Sheet
    private var addToWatchSheet: some View {
        NavigationStack {
            List {
                Section("Add to watchlist") {
                    ForEach(lookup.watchlists, id: \.id) { wl in
                        let isAll = wl.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            .localizedCaseInsensitiveCompare("All") == .orderedSame
                        if !isAll {
                            let isMember = accountWatchlists.contains(where: { $0.id == wl.id })
                            Button {
                                if isMember {
                                    removingWatchlistId = wl.id
                                    Task {
                                        do {
                                            try await RestClient().unlinkWatchlistAccount(watchlistId: wl.id, accountId: account.id)
                                            await loadAccountWatches()
                                            banners.show(
                                                AppBanner(
                                                    icon: "checkmark.circle",
                                                    title: "Removed from watchlist",
                                                    message: "\(account.name) ← \(wl.name)",
                                                    style: .success
                                                )
                                            )
                                            Haptics.success()
                                        } catch let api as APIError {
                                            Haptics.softImpact()
                                            banners.showError(message: api.errorDescription ?? "Failed to remove from watchlist.")
                                        } catch {
                                            Haptics.softImpact()
                                            banners.showError(message: error.localizedDescription)
                                        }
                                        removingWatchlistId = nil
                                    }
                                } else {
                                    addingWatchlistId = wl.id
                                    Task {
                                        do {
                                            try await RestClient().linkWatchlistAccount(watchlistId: wl.id, accountId: account.id)
                                            await loadAccountWatches()
                                            banners.show(
                                                AppBanner(
                                                    icon: "checkmark.circle.fill",
                                                    title: "Added to watchlist",
                                                    message: "\(account.name) → \(wl.name)",
                                                    style: .success
                                                )
                                            )
                                            Haptics.success()
                                        } catch let api as APIError {
                                            Haptics.softImpact()
                                            banners.showError(message: api.errorDescription ?? "Failed to add to watchlist.")
                                        } catch {
                                            Haptics.softImpact()
                                            banners.showError(message: error.localizedDescription)
                                        }
                                        addingWatchlistId = nil
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(wl.name)
                                    Spacer()
                                    if removingWatchlistId == wl.id || addingWatchlistId == wl.id {
                                        ProgressView().progressViewStyle(.circular)
                                    } else if isMember {
                                        Text("Remove")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundColor(.airbnbPrimary)
                                    } else {
                                        Text("Add")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundColor(.airbnbPrimary)
                                    }
                                }
                            }
                            .disabled(removingWatchlistId != nil || addingWatchlistId != nil)
                        }
                    }
                }
            }
            .navigationTitle("Add to watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { showAddToWatchSheet = false } }
            }
            .task {
                await lookup.refreshWatchlists(userId: account.userId)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @MainActor
    private func searchHoldings() async {
        let q = holdingSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            holdingResults = []
            return
        }
        isSearchingHolding = true
        defer { isSearchingHolding = false }
        do {
            let results = try await YahooFinanceClient().search(query: q)
            holdingResults = results.filter { !$0.symbol.isEmpty }
        } catch {
            banners.showError(message: error.localizedDescription)
        }
    }

    @MainActor
    private func createHolding(from quote: YahooFinanceClient.Quote) async {
        do {
            let name = quote.longname ?? quote.shortname ?? quote.symbol
            _ = try await RestClient().createHolding(accountId: account.id, name: name, symbol: quote.symbol)
            showAddHoldingSheet = false
            await loadBroker()
            banners.show(AppBanner(icon: "checkmark.circle.fill", title: "Holding added", message: "\(name)", style: .success))
        } catch let api as APIError {
            showAddHoldingSheet = false
            banners.showError(message: api.errorDescription ?? "Failed to add holding")
        } catch {
            showAddHoldingSheet = false
            banners.showError(message: error.localizedDescription)
        }
    }
}
