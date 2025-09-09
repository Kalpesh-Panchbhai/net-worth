import Foundation
import SwiftUI
import Combine

@MainActor
final class IncomeController: ObservableObject {
    @Published var incomes: [Income] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedTypes: Set<String> = [] // Sources
    @Published var selectedTags: Set<String> = []
    @Published var selectedYears: Set<Int> = []
    @Published var selectedFYs: Set<FinancialYear> = []
    // Grouping selection for the list view
    @Published var grouping: Grouping = .month

    enum Grouping: String, CaseIterable, Identifiable {
        case month = "Month"
        case tag = "Tag"
        case source = "Source"
        case year = "Year"
        case fy = "FY"
        var id: String { rawValue }
        var title: String { rawValue }
    }
    
    let userId: Int
    private let client: RestClient
    private let calendar = Calendar.current
    private var store: LookupStore? = nil
    private var cancellables = Set<AnyCancellable>()
    
    init(userId: Int, service: RestClient = RestClient()) {
        self.userId = userId
        self.client = service
    }
    
    func attachStore(_ store: LookupStore) {
        guard self.store == nil else { return }
        self.store = store
        // Immediately sync with existing data
        self.incomes = store.incomes.sorted { $0.creditedDate > $1.creditedDate }
        store.$incomes
            .sink { [weak self] list in
                self?.incomes = list.sorted { $0.creditedDate > $1.creditedDate }
            }
            .store(in: &cancellables)
    }

    func load() async {
        if let store = store {
            // Only load if we don't have data and aren't already loading
            if store.incomes.isEmpty && !store.isLoadingIncomes {
                isLoading = true
                errorMessage = nil
                await store.loadIncomesIfNeeded(userId: userId)
                isLoading = false
            }
            return
        }
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let list = try await client.fetchIncomes(userId: userId)
            self.incomes = list.sorted { $0.creditedDate > $1.creditedDate }
        } catch let api as APIError {
            // Suppress banners for user-initiated cancellations (common with pull-to-refresh overlapping loads)
            if case .transport(let err) = api, let urlErr = err as? URLError, urlErr.code == .cancelled {
                return
            }
            self.errorMessage = api.errorDescription ?? "Request failed"
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func refresh() async {
        if let store = store { await store.refreshIncomes(userId: userId) }
        else { await load() }
    }
    
    // Delete an income by calling backend and updating local state
    func delete(_ income: Income) async -> Bool {
        errorMessage = nil
        do {
            try await client.deleteIncome(id: income.id)
            // Update local list
            incomes.removeAll { $0.id == income.id }
            if let store = store { await store.refreshIncomes(userId: userId) }
            return true
        } catch let api as APIError {
            if case .transport(let err) = api, let urlErr = err as? URLError, urlErr.code == .cancelled {
                return false
            }
            self.errorMessage = api.errorDescription ?? "Delete failed"
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    // Update an income by calling backend and updating local state
    func update(
        _ income: Income,
        incomeSourceId: Int? = nil,
        incomeTagId: Int? = nil,
        netAmount: Double? = nil,
        taxPaid: Double? = nil,
        creditedDate: Date? = nil,
        currency: String? = nil
    ) async -> Bool {
        errorMessage = nil
        do {
            let updatedIncome = try await client.updateIncome(
                id: income.id,
                incomeSourceId: incomeSourceId,
                incomeTagId: incomeTagId,
                netAmount: netAmount,
                taxPaid: taxPaid,
                creditedDate: creditedDate,
                currency: currency
            )
            // Update local list
            if let index = incomes.firstIndex(where: { $0.id == income.id }) {
                incomes[index] = updatedIncome
            }
            if let store = store { await store.refreshIncomes(userId: userId) }
            return true
        } catch let api as APIError {
            if case .transport(let err) = api, let urlErr = err as? URLError, urlErr.code == .cancelled {
                return false
            }
            self.errorMessage = api.errorDescription ?? "Update failed"
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    // Create a new income by calling backend and updating local state
    func create(
        incomeSourceId: Int,
        incomeTagId: Int,
        netAmount: Double,
        taxPaid: Double? = nil,
        creditedDate: Date,
        currency: String
    ) async -> Bool {
        errorMessage = nil
        do {
            let newIncome = try await client.createIncome(
                userId: userId,
                incomeSourceId: incomeSourceId,
                incomeTagId: incomeTagId,
                netAmount: netAmount,
                taxPaid: taxPaid,
                creditedDate: creditedDate,
                currency: currency
            )
            // Add to local list
            incomes.append(newIncome)
            incomes.sort { $0.creditedDate > $1.creditedDate }
            if let store = store { await store.refreshIncomes(userId: userId) }
            return true
        } catch let api as APIError {
            // Gracefully handle one-income-per-date rule (HTTP 409)
            if case .apiError(let status, let serverErr) = api, status == 409 {
                self.errorMessage = serverErr.message.isEmpty
                    ? "An income for this date already exists. Choose a different date or edit the existing entry."
                    : serverErr.message
                return false
            }
            if case .transport(let err) = api, let urlErr = err as? URLError, urlErr.code == .cancelled {
                return false
            }
            self.errorMessage = api.errorDescription ?? "Create failed"
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    var uniqueTypes: [String] {
        guard let store = store else { return [] }
        let sourceIds = Set(incomes.map { $0.incomeSourceId })
        return store.incomeSources.filter { sourceIds.contains($0.id) }.map { $0.name }.sorted()
    }
    var uniqueTags: [String] {
        guard let store = store else { return [] }
        let tagIds = Set(incomes.map { $0.incomeTagId })
        return store.incomeTags.filter { tagIds.contains($0.id) }.map { $0.name }.sorted()
    }
    var availableYears: [Int] {
        let years = incomes.map { Calendar.current.component(.year, from: $0.creditedDate) }
        return Array(Set(years)).sorted(by: >)
    }
    struct FinancialYear: Identifiable, Hashable {
        let startYear: Int // e.g., 2024 represents FY 2024-25 (Apr 1, 2024 ... Mar 31, 2025)
        var id: Int { startYear }
        var title: String { "FY \(startYear)-\(String(format: "%02d", (startYear + 1) % 100))" }
        var startDate: Date { Calendar.current.date(from: DateComponents(year: startYear, month: 4, day: 1)) ?? Date() }
        var endDateExclusive: Date { Calendar.current.date(from: DateComponents(year: startYear + 1, month: 4, day: 1)) ?? Date() }
    }
    var availableFYs: [FinancialYear] {
        let cal = Calendar.current
        let startYears: [Int] = incomes.map { income in
            let comp = cal.dateComponents([.year, .month], from: income.creditedDate)
            guard let y = comp.year, let m = comp.month else { return 0 }
            return m >= 4 ? y : (y - 1)
        }
        let setYears = Set(startYears.filter { $0 > 0 })
        return setYears.map { FinancialYear(startYear: $0) }.sorted { $0.startYear > $1.startYear }
    }
    
    var filtered: [Income] {
        guard let store = store else { return incomes }
        return incomes.filter { income in
            // Source filter
            let sourceName = store.incomeSources.first { $0.id == income.incomeSourceId }?.name ?? ""
            let sourceMatch = selectedTypes.isEmpty || selectedTypes.contains(sourceName)
            // Tag filter
            let tagName = store.incomeTags.first { $0.id == income.incomeTagId }?.name ?? ""
            let tagMatch = selectedTags.isEmpty || selectedTags.contains(tagName)
            
            return sourceMatch && tagMatch &&
            // Financial Year filter
            {
                if selectedFYs.isEmpty { return true }
                let comp = calendar.dateComponents([.year, .month], from: income.creditedDate)
                guard let y = comp.year, let m = comp.month else { return true }
                let startYear = m >= 4 ? y : (y - 1)
                return selectedFYs.contains(FinancialYear(startYear: startYear))
            }() &&
            // Calendar Year filter
            (selectedYears.isEmpty || selectedYears.contains(calendar.component(.year, from: income.creditedDate)))
        }
    }
    
    struct Section: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let items: [Income]
    }
    
    var sections: [Section] {
        switch grouping {
        case .month:
            // Group by calendar month
            let grouped = Dictionary(grouping: filtered) { income in
                calendar.date(
                    from: calendar.dateComponents([.year, .month], from: income.creditedDate)
                ) ?? income.creditedDate
            }
            let keys = grouped.keys.sorted(by: >)
            return keys.map { month in
                let items = (grouped[month] ?? []).sorted { $0.creditedDate > $1.creditedDate }
                return Section(title: DateFormatter.monthYear.string(from: month), items: items)
            }

        case .tag:
            // Group by income tag name
            guard let store = store else { return [] }
            let grouped = Dictionary(grouping: filtered) { income in
                store.incomeTags.first { $0.id == income.incomeTagId }?.name ?? "Unknown"
            }
            let keys = grouped.keys.sorted(by: <)
            return keys.map { tag in
                let items = (grouped[tag] ?? []).sorted { $0.creditedDate > $1.creditedDate }
                return Section(title: tag, items: items)
            }

        case .source:
            // Group by income source name
            guard let store = store else { return [] }
            let grouped = Dictionary(grouping: filtered) { income in
                store.incomeSources.first { $0.id == income.incomeSourceId }?.name ?? "Unknown"
            }
            let keys = grouped.keys.sorted(by: <)
            return keys.map { source in
                let items = (grouped[source] ?? []).sorted { $0.creditedDate > $1.creditedDate }
                return Section(title: source, items: items)
            }

        case .year:
            // Group by calendar year
            let grouped = Dictionary(grouping: filtered) {
                calendar.component(.year, from: $0.creditedDate)
            }
            let keys = grouped.keys.sorted(by: >)
            return keys.map { year in
                let items = (grouped[year] ?? []).sorted { $0.creditedDate > $1.creditedDate }
                return Section(title: String(year), items: items)
            }

        case .fy:
            // Group by financial year starting April 1
            let grouped = Dictionary(grouping: filtered) { income -> Int in
                let comp = calendar.dateComponents([.year, .month], from: income.creditedDate)
                let y = comp.year ?? 0
                let m = comp.month ?? 1
                return m >= 4 ? y : (y - 1)
            }
            let keys = grouped.keys.filter { $0 > 0 }.sorted(by: >)
            return keys.map { startYear in
                let title = FinancialYear(startYear: startYear).title
                let items = (grouped[startYear] ?? []).sorted { $0.creditedDate > $1.creditedDate }
                return Section(title: title, items: items)
            }
        }
    }
    
    // Totals per new semantics: Total = netAmount + taxPaid, Net = netAmount, Tax = taxPaid
    var totalAll: Double { incomes.reduce(0) { $0 + $1.netAmount + $1.taxPaid } }
    var totalTaxPaid: Double { incomes.reduce(0) { $0 + $1.taxPaid } }
    var totalNet: Double { incomes.reduce(0) { $0 + $1.netAmount } }
    // Filtered totals for summary when filters are applied
    var filteredTotalAll: Double { filtered.reduce(0) { $0 + $1.netAmount + $1.taxPaid } }
    var filteredTotalTax: Double { filtered.reduce(0) { $0 + $1.taxPaid } }
    var filteredTotalNet: Double { filtered.reduce(0) { $0 + $1.netAmount } }
    var totalThisMonth: Double {
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return 0 }
        return incomes.filter { $0.creditedDate >= start }.reduce(0) { $0 + $1.netAmount + $1.taxPaid }
    }
    var avgLast3Months: Double {
        let now = Date()
        let months = (0..<3).compactMap { calendar.date(byAdding: .month, value: -$0, to: now) }
        let starts = months.compactMap { calendar.date(from: calendar.dateComponents([.year, .month], from: $0)) }
        let monthSums: [Double] = starts.map { start in
            let end = calendar.date(byAdding: DateComponents(month: 1, day: 0), to: start) ?? start
            let sum = incomes.filter { $0.creditedDate >= start && $0.creditedDate < end }.reduce(0) { $0 + $1.netAmount + $1.taxPaid }
            return sum
        }
        guard !monthSums.isEmpty else { return 0 }
        return monthSums.reduce(0, +) / Double(monthSums.count)
    }
    
    // Sums for the last 12 months (oldest -> latest) for sparkline
    var monthlySumsLast12: [Double] {
        guard let startOfCurrent = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return [] }
        return (0..<12).reversed().map { offset in
            let start = calendar.date(byAdding: .month, value: -offset, to: startOfCurrent) ?? Date()
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
            return incomes.filter { $0.creditedDate >= start && $0.creditedDate < end }
                .reduce(0) { $0 + $1.netAmount + $1.taxPaid }
        }
    }
    
    var displayCurrency: String {
        incomes.first?.currency ?? Locale.current.currency?.identifier ?? "USD"
    }
}

// Backwards compatibility for existing views
@available(*, deprecated, message: "Use IncomeController instead")
typealias IncomeViewModel = IncomeController
