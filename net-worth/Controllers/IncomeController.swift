import Foundation
import SwiftUI

@MainActor
final class IncomeController: ObservableObject {
    @Published var incomes: [Income] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedType: String? = nil
    
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
    
    var filtered: [Income] {
        if let type = selectedType, !type.isEmpty {
            return incomes.filter { $0.incomeType.name == type }
        }
        return incomes
    }
    
    struct Section: Identifiable, Hashable {
        let id = UUID()
        let month: Date
        let title: String
        let items: [Income]
    }
    
    var sections: [Section] {
        let grouped = Dictionary(grouping: filtered) { income in
            calendar.date(from: calendar.dateComponents([.year, .month], from: income.creditedDate)) ?? income.creditedDate
        }
        let mapped = grouped.map { (month, items) in
            Section(month: month, title: DateFormatter.monthYear.string(from: month), items: items.sorted { $0.creditedDate > $1.creditedDate })
        }
        return mapped.sorted { $0.month > $1.month }
    }
    
    var totalAll: Double { incomes.reduce(0) { $0 + $1.amount } }
    var totalTaxPaid: Double { incomes.reduce(0) { $0 + $1.taxPaid } }
    var totalNet: Double { max(0, totalAll - totalTaxPaid) }
    var totalThisMonth: Double {
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return 0 }
        return incomes.filter { $0.creditedDate >= start }.reduce(0) { $0 + $1.amount }
    }
    var avgLast3Months: Double {
        let now = Date()
        let months = (0..<3).compactMap { calendar.date(byAdding: .month, value: -$0, to: now) }
        let starts = months.compactMap { calendar.date(from: calendar.dateComponents([.year, .month], from: $0)) }
        let monthSums: [Double] = starts.map { start in
            let end = calendar.date(byAdding: DateComponents(month: 1, day: 0), to: start) ?? start
            let sum = incomes.filter { $0.creditedDate >= start && $0.creditedDate < end }.reduce(0) { $0 + $1.amount }
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
                .reduce(0) { $0 + $1.amount }
        }
    }
    
    var displayCurrency: String {
        incomes.first?.currency ?? Locale.current.currency?.identifier ?? "USD"
    }
}

// Backwards compatibility for existing views
@available(*, deprecated, message: "Use IncomeController instead")
typealias IncomeViewModel = IncomeController
