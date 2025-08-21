import SwiftUI

struct IncomeTypesView: View {
    let userId: Int
    var body: some View {
        NamedEntitiesListView<IncomeType>(
            title: "Income sources",
            userId: userId,
            regularIcon: "creditcard",
            defaultIcon: "creditcard.fill",
            useStore: true,
            fetch: { service, uid in try await service.fetchIncomeTypes(userId: uid) },
            setDefault: { service, item in try await service.setDefault(incomeType: item) },
            create: { service, uid, name, isDefault in try await service.createIncomeType(userId: uid, name: name, isDefault: isDefault) }
        )
    }
}
