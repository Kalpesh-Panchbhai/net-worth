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
    @State private var updateWatchListViewOpen = false
    
    private var watchController = WatchController()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(watchViewModel.watchList, id: \.self) { watchList in
                    NavigationLink(destination: {
                        SingleWatchListView(watchList: watchList)
                    }, label: {
                        Text(watchList.accountName)
                    })
                    .swipeActions(edge: .leading, content: {
                        if(watchList.accountName != "All") {
                            Button("Update") {
                                Task.init {
                                    await watchViewModel.getWatchList(id: watchList.id!)
                                }
                                self.updateWatchListViewOpen.toggle()
                            }
                            .tint(.green)
                        }
                    })
                    .swipeActions(edge: .trailing, content: {
                        if(watchList.accountName != "All") {
                            Button("Delete") {
                                watchController.deleteWatchList(watchList: watchList)
                                Task.init {
                                    await watchViewModel.getAllWatchList()
                                }
                            }
                            .tint(.red)
                        }
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
            .halfSheet(showSheet: $updateWatchListViewOpen) {
                UpdateWatchView(watchViewModel: watchViewModel)
            }
            .onAppear {
                Task.init {
                    await watchViewModel.getAllWatchList()
                }
            }
            .navigationTitle("Watch List")
        }
    }
    
    private func deleteIncome(offsets: IndexSet) {
        var id = ""
        withAnimation {
            offsets.map {
                id = watchViewModel.watchList[$0].id!
            }.forEach {
                var watch = Watch()
                watch.id = id
                watchController.deleteWatchList(watchList: watch)
                Task.init {
                    await watchViewModel.getAllWatchList()
                }
            }
        }
    }
}
