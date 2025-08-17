import SwiftUI

struct IncomeTypesView: View {
    let userId: Int
    var body: some View {
        NamedEntitiesListView<IncomeType>(
            title: "Income types",
            userId: userId,
            regularIcon: "list.bullet",
            defaultIcon: "star.fill",
            fetch: { service, uid in try await service.fetchIncomeTypes(userId: uid) }
        )
    }
}
