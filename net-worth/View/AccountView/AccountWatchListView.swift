//
//  AccountWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 04/05/23.
//

import SwiftUI

struct AccountWatchListView: View {
    
    var account: Account
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    List {
                        ForEach(watchViewModel.watchListForAccount, id: \.self, content: { watch in
                            NavigationLink(destination: {
                                SingleWatchListView(watch: watch)
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
                    }
                }
            }
        }
    }
}
