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
            VStack {
                HStack {
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
                        .listRowBackground(Color.theme.background)
                        .foregroundColor(Color.theme.text)
                    }
                    .shadow(color: Color.theme.text.opacity(0.3),radius: 10, x: 0, y: 5)
                    .background(Color.theme.background)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
}
