import Foundation
import SwiftUI

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
    private let service: IncomeService
    private let calendar = Calendar.current
    
    init(userId: Int, service: IncomeService = IncomeService()) {
        self.userId = userId
        self.service = service
    }
    
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let list = try await service.fetchIncomes(userId: userId)
            self.incomes = list.sorted { $0.creditedDate > $1.creditedDate }
        } catch {
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
    
    func refresh() async { await load() }
    
    var uniqueTypes: [String] {
        Array(Set(incomes.map { $0.incomeType.name })).sorted()
    }
    var uniqueTags: [String] {
        Array(Set(incomes.map { $0.incomeTag.name })).sorted()
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
        incomes.filter { income in
            // Source filter
            (selectedTypes.isEmpty || selectedTypes.contains(income.incomeType.name)) &&
            // Tag filter
            (selectedTags.isEmpty || selectedTags.contains(income.incomeTag.name)) &&
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
            let grouped = Dictionary(grouping: filtered) { $0.incomeTag.name }
            let keys = grouped.keys.sorted(by: <)
            return keys.map { tag in
                let items = (grouped[tag] ?? []).sorted { $0.creditedDate > $1.creditedDate }
                return Section(title: tag, items: items)
            }

        case .source:
            // Group by income type/source name
            let grouped = Dictionary(grouping: filtered) { $0.incomeType.name }
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
    
    // Totals per new semantics: Total = amount + taxPaid, Net = amount, Tax = taxPaid
    var totalAll: Double { incomes.reduce(0) { $0 + $1.amount + $1.taxPaid } }
    var totalTaxPaid: Double { incomes.reduce(0) { $0 + $1.taxPaid } }
    var totalNet: Double { incomes.reduce(0) { $0 + $1.amount } }
    // Filtered totals for summary when filters are applied
    var filteredTotalAll: Double { filtered.reduce(0) { $0 + $1.amount + $1.taxPaid } }
    var filteredTotalTax: Double { filtered.reduce(0) { $0 + $1.taxPaid } }
    var filteredTotalNet: Double { filtered.reduce(0) { $0 + $1.amount } }
    var totalThisMonth: Double {
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return 0 }
        return incomes.filter { $0.creditedDate >= start }.reduce(0) { $0 + $1.amount + $1.taxPaid }
    }
    var avgLast3Months: Double {
        let now = Date()
        let months = (0..<3).compactMap { calendar.date(byAdding: .month, value: -$0, to: now) }
        let starts = months.compactMap { calendar.date(from: calendar.dateComponents([.year, .month], from: $0)) }
        let monthSums: [Double] = starts.map { start in
            let end = calendar.date(byAdding: DateComponents(month: 1, day: 0), to: start) ?? start
            let sum = incomes.filter { $0.creditedDate >= start && $0.creditedDate < end }.reduce(0) { $0 + $1.amount + $1.taxPaid }
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
                .reduce(0) { $0 + $1.amount + $1.taxPaid }
        }
    }
    
    var displayCurrency: String {
        incomes.first?.currency ?? Locale.current.currency?.identifier ?? "USD"
    }
}

// Backwards compatibility for existing views
@available(*, deprecated, message: "Use IncomeController instead")
typealias IncomeViewModel = IncomeController
