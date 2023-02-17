//
//  WatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 17/02/23.
//

import SwiftUI

struct WatchListView: View {
    
    @StateObject var watchViewModel = WatchViewModel()
    
    @State private var newWatchListViewOpen = false
    
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
            .toolbar {
                ToolbarItem(content: {
                    Button(action: {
                        self.newWatchListViewOpen.toggle()
                    }, label: {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    })
                })
            }
            .halfSheet(showSheet: $newWatchListViewOpen) {
                NewWatchView(watchViewModel: watchViewModel)
            }
            .onAppear {
                Task.init {
                    await watchViewModel.getAllWatchList()
                }
            }
            .navigationTitle("Watch List")
        }
    }
}
