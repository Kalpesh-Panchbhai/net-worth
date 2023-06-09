//
//  WatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 17/02/23.
//

import SwiftUI

struct WatchView: View {
    
    var watchController = WatchController()
    
    @State var newWatchListViewOpen = false
    @State var updateWatchViewOpen = false
    
    @StateObject var watchViewModel: WatchViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                if (!watchViewModel.watchListLoad) {
                    //MARK: Loading View
                    LoadingView()
                } else {
                    List {
                        ForEach(watchViewModel.watchList, id: \.self) { watchList in
                            NavigationLink(destination: {
                                WatchDetailView(watch: watchList, watchViewModel: watchViewModel)
                                    .toolbarRole(.editor)
                            }, label: {
                                HStack {
                                    Text(watchList.accountName)
                                    Spacer()
                                    Text("\(watchList.accountID.count)")
                                        .font(.system(size: 12))
                                }
                            })
                            .contextMenu {
                                Label(watchList.id!, systemImage: "info.square")
                            }
                            // MARK: Update
                            .swipeActions(edge: .leading, content: {
                                if(watchList.accountName != "All") {
                                    Button("Update") {
                                        Task.init {
                                            await watchViewModel.getWatchList(id: watchList.id!)
                                        }
                                        self.updateWatchViewOpen.toggle()
                                    }
                                    .tint(Color.theme.green)
                                }
                            })
                            // MARK: Delete
                            .swipeActions(edge: .trailing, content: {
                                if(watchList.accountName != "All") {
                                    Button("Delete") {
                                        watchController.deleteWatchList(watchList: watchList)
                                        Task.init {
                                            await watchViewModel.getAllWatchList()
                                        }
                                    }
                                    .tint(Color.theme.red)
                                }
                            })
                        }
                        .listRowBackground(Color.theme.foreground)
                    }
                    .foregroundColor(Color.theme.primaryText)
                    .refreshable {
                        Task.init {
                            await watchViewModel.getAllWatchList()
                        }
                    }
                }
            }
            .toolbar {
                // MARK: Add New Watch ToolbarItem
                ToolbarItem(content: {
                    Button(action: {
                        self.newWatchListViewOpen.toggle()
                    }, label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.theme.primaryText)
                            .bold()
                    })
                    .font(.system(size: 14).bold())
                })
            }
            // MARK: New Watch Sheet View
            .sheet(isPresented: $newWatchListViewOpen) {
                NewWatchView(watchViewModel: watchViewModel)
                    .presentationDetents([.medium])
            }
            // MARK: Update Watch Sheet View
            .sheet(isPresented: $updateWatchViewOpen) {
                UpdateWatchView(watchViewModel: watchViewModel)
                    .presentationDetents([.medium])
            }
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
            .navigationTitle("Watch Lists")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
