import Foundation
import SwiftUI

@MainActor
final class LookupStore: ObservableObject {
    @Published private(set) var incomeTypes: [IncomeType] = []
    @Published private(set) var incomeTags: [IncomeTag] = []

    private var typesLoaded = false
    private var tagsLoaded = false
    private var typesRefreshing = false
    private var tagsRefreshing = false
    private let client = RestClient()

    func loadIfNeeded(userId: Int) async {
        async let a: Void = loadIncomeTypesIfNeeded(userId: userId)
        async let b: Void = loadIncomeTagsIfNeeded(userId: userId)
        _ = await (a, b)
    }

    func loadIncomeTypesIfNeeded(userId: Int) async {
        if typesLoaded { return }
        do {
            let list = try await client.fetchIncomeTypes(userId: userId)
            self.incomeTypes = list
            self.typesLoaded = true
        } catch {
            // keep empty; caller can retry
        }
    }

    func loadIncomeTagsIfNeeded(userId: Int) async {
        if tagsLoaded { return }
        do {
            let list = try await client.fetchIncomeTags(userId: userId)
            self.incomeTags = list
            self.tagsLoaded = true
        } catch {
            // keep empty; caller can retry
        }
    }

    // Explicit refreshers (allowed after mutations)
    func refreshIncomeTypes(userId: Int) async {
        if typesRefreshing { return }
        typesRefreshing = true
        defer { typesRefreshing = false }
        do {
            let list = try await client.fetchIncomeTypes(userId: userId)
            self.incomeTypes = list
            self.typesLoaded = true
        } catch {
            // no-op
        }
    }

    func refreshIncomeTags(userId: Int) async {
        if tagsRefreshing { return }
        tagsRefreshing = true
        defer { tagsRefreshing = false }
        do {
            let list = try await client.fetchIncomeTags(userId: userId)
            self.incomeTags = list
            self.tagsLoaded = true
        } catch {
            // no-op
        }
    }
}
