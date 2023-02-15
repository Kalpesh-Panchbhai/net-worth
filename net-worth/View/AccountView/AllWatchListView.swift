//
//  AllWatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 15/02/23.
//

import SwiftUI

struct AllWatchListView: View {
    
    @StateObject var watchViewModel: WatchViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(watchViewModel.watchList, id: \.self) { watchList in
                    NavigationLink(destination: {
                        SingleWatchListView(watchList: watchList)
                    }, label: {
                        Text(watchList.accountName)
                    })
                }
            }
        }
    }
}
