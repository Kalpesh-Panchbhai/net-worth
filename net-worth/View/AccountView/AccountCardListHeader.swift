//
//  AccountCardListHeader.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 12/06/23.
//

import SwiftUI

struct AccountCardListHeader: View {
    
    var accountType: String
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    var body: some View {
        HStack {
            Text(accountType.uppercased())
                .foregroundColor(Color.theme.primaryText)
                .bold()
                .font(.system(size: 15))
            Spacer()
            NavigationLink(destination: {
                AccountListView(accountType: accountType, watchViewModel: watchViewModel)
                    .toolbarRole(.editor)
            }, label: {
                Text("See all")
                    .foregroundColor(Color.theme.primaryText)
                    .bold()
                    .font(.system(size: 15))
            })
        }
        .padding(.horizontal, 15)
    }
}
