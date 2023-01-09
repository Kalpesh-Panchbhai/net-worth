//
//  CardsScreen.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 07/01/23.
//

import SwiftUI
import CoreData

struct CardsScreen: View {
    
    @SectionedFetchRequest<String, Account>(
        sectionIdentifier: \.accounttype!,
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.timestamp, ascending: true)],
        animation: .default
    )
    private var accounts: SectionedFetchResults<String, Account>
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(#colorLiteral(red: 0.9646216035, green: 0.9647607207, blue: 0.9998810887, alpha: 1)).edgesIgnoringSafeArea(.all)
                ScrollView(.vertical) {
                    ForEach(accounts) { section in
                        Section(header: Text(section.id)) {
                            ScrollView(.horizontal, showsIndicators: true) {
                                LazyHStack {
                                    ForEach(section, id: \.self) { account in
                                        CardView(isSelected: true, account: account)
                                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 5, y: 5)
                                    }
                                }
                                .padding(20)
                            }
                        }
                    }
                }
            }
            .foregroundColor(Color.black)
        }
    }
}

struct CardsScreen_Previews: PreviewProvider {
    static var previews: some View {
        CardsScreen()
    }
}
