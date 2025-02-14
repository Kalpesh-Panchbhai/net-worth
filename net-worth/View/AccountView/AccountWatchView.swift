//
//  AccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/23.
//

import SwiftUI

struct AccountWatchView: View {
    
    @EnvironmentObject var watchViewModel: WatchViewModel
    @EnvironmentObject var watchAccountViewModel: WatchAccountViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(getWatchListData(), id: \.self, content: { watch in
                    NavigationLink(destination: {
                        WatchDetailView(watch: watch)
                            .toolbarRole(.editor)
                    }, label: {
                        WatchViewRow(watch: watch)
                            .badge(
                                Text("\(watch.totalAccount)")
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
    
    private func getWatchListData() -> [WatchRestModel] {
        let WatchListForAccount = watchAccountViewModel.allWatchListByAccountID.map {$0.watchId}
        var watchList = watchViewModel.watchList.filter {
            return WatchListForAccount.contains($0.id)
        }
        return watchList
    }
}
