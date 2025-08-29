import SwiftUI

struct IncomeTypesView: View {
    let userId: Int
    var body: some View {
        NamedEntitiesListView<IncomeSource>(
            title: "Income sources",
            userId: userId,
            regularIcon: "creditcard",
            defaultIcon: "creditcard.fill",
            useStore: true,
            fetch: { service, uid in try await service.fetchIncomeSources(userId: uid) },
            setDefault: { service, item in try await service.setDefaultIncomeSource(id: item.id) },
            create: { service, uid, name, isDefault in try await service.createIncomeSource(userId: uid, name: name, isDefault: isDefault) }
        )
    }
}
