//
//  AccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/23.
//

import SwiftUI

struct AccountWatchListView: View {
    
    var account: Account
    
    @ObservedObject var watchViewModel = WatchViewModel()
    
    var body: some View {
        VStack {
            HStack {
                List {
                    ForEach(watchViewModel.watchList, id: \.self, content: { watch in
                        Text(watch.accountName)
                            .contextMenu {
                                Label(watch.id!, systemImage: "info.square")
                            }
                    })
                }
            }
        }
        .onAppear {
            Task.init {
                await watchViewModel.getWatchListByAccount(accountID: account.id!)
            }
        }
    }
}
