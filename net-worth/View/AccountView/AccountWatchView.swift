//
//  AccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/23.
//

import SwiftUI

struct AccountWatchView: View {
    
    @ObservedObject var watchViewModel: WatchViewModel
    @ObservedObject var accountViewModel: AccountViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(watchViewModel.watchListForAccount, id: \.self, content: { watch in
                    NavigationLink(destination: {
                        WatchDetailView(watch: watch, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                            .toolbarRole(.editor)
                    }, label: {
                        WatchViewRow(watch: watch, accountViewModel: accountViewModel)
                            .badge(
                                Text("\(watch.accountList.count)")
                                    .foregroundColor(Color.theme.secondaryText)
                                    .font(.caption.italic())
                            )
                    })
                })
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
        }
    }
}
