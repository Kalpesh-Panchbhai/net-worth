//
//  AccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/23.
//

import SwiftUI

struct AccountWatchView: View {
    
    var account: Account
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(watchViewModel.watchListForAccount, id: \.self, content: { watch in
                    NavigationLink(destination: {
                        WatchDetailView(watch: watch, watchViewModel: watchViewModel)
                            .toolbarRole(.editor)
                    }, label: {
                        HStack {
                            Text(watch.accountName)
                            Spacer()
                            Text("\(watch.accountID.count)")
                                .font(.system(size: 12))
                        }
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
