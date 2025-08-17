import SwiftUI

struct IncomeTagsView: View {
    let userId: Int
    var body: some View {
        NamedEntitiesListView<IncomeTag>(
            title: "Income tags",
            userId: userId,
            regularIcon: "tag",
            defaultIcon: "tag.fill",
            fetch: { service, uid in try await service.fetchIncomeTags(userId: uid) },
            setDefault: { service, item in try await service.setDefault(incomeTag: item) }
        )
    }
}
