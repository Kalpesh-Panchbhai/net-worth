//
//  AccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/23.
//

import SwiftUI

struct AccountWatchView: View {
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(watchViewModel.watchListForAccount, id: \.self, content: { watch in
                    NavigationLink(destination: {
                        WatchDetailView(watch: watch, watchViewModel: watchViewModel)
                            .toolbarRole(.editor)
                    }, label: {
                        WatchViewRow(watch: watch)
                    })
                    .contextMenu {
                        Label(watch.id!, systemImage: "info.square")
                    }
                })
                .listRowBackground(Color.theme.foreground)
                .foregroundColor(Color.theme.primaryText)
            }
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
        }
    }
}
