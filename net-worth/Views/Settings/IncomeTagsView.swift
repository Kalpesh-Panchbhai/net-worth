import SwiftUI

struct IncomeTagsView: View {
    let userId: Int
    var body: some View {
        NamedEntitiesListView<IncomeTag>(
            title: "Income tags",
            userId: userId,
            regularIcon: "tag",
            defaultIcon: "tag.fill",
            useStore: true,
            fetch: { service, uid in try await service.fetchIncomeTags(userId: uid) },
            setDefault: { service, item in try await service.setDefault(incomeTag: item) },
            create: { service, uid, name, isDefault in try await service.createIncomeTag(userId: uid, name: name, isDefault: isDefault) }
        )
    }
}
