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
                        ForEach(watchViewModel.watchList, id: \.self) { watch in
                            NavigationLink(destination: {
                                WatchDetailView(watch: watch, watchViewModel: watchViewModel)
                                    .toolbarRole(.editor)
                            }, label: {
                                WatchViewRow(watch: watch)
                                    .badge(
                                        Text("\(watch.accountID.count)")
                                            .foregroundColor(Color.theme.secondaryText)
                                            .font(.caption.italic())
                                    )
                            })
                            .contextMenu {
                                Label(watch.id!, systemImage: ConstantUtils.infoIconImageName)
                            }
                            // MARK: Update
                            .swipeActions(edge: .leading, content: {
                                if(watch.accountName != "All") {
                                    Button("Update") {
                                        Task.init {
                                            await watchViewModel.getWatchList(id: watch.id!)
                                        }
                                        self.updateWatchViewOpen.toggle()
                                    }
                                    .tint(Color.theme.green)
                                }
                            })
                            // MARK: Delete
                            .swipeActions(edge: .trailing, content: {
                                if(watch.accountName != "All") {
                                    Button("Delete") {
                                        watchController.deleteWatchList(watchList: watch)
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
                        Image(systemName: ConstantUtils.plusImageName)
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
