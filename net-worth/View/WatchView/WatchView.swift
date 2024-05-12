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
    @StateObject var accountViewModel: AccountViewModel
    
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
                                WatchDetailView(watch: watch, accountViewModel: accountViewModel, watchViewModel: watchViewModel)
                                    .toolbarRole(.editor)
                            }, label: {
                                WatchViewRow(watch: watch, accountViewModel: accountViewModel)
                                    .badge(
                                        Text("\(watch.accountList.count)")
                                            .foregroundColor(Color.theme.secondaryText)
                                            .font(.caption.italic())
                                    )
                            })
                            // MARK: Update
                            .swipeActions(edge: .leading, content: {
                                if(!watch.name.elementsEqual("All")) {
                                    Button("Update") {
                                        self.updateWatchViewOpen.toggle()
                                    }
                                    .tint(Color.theme.green)
                                }
                            })
                            .sheet(isPresented: $updateWatchViewOpen) {
                                UpdateWatchView(watch: watch, watchViewModel: watchViewModel)
                                    .presentationDetents([.medium])
                            }
                            // MARK: Delete
                            .swipeActions(edge: .trailing, content: {
                                if(!watch.name.elementsEqual("All")) {
                                    Button("Delete") {
                                        Task.init {
                                            await watchController.deleteWatchList(watch: watch)
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
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
            .navigationTitle("Watch Lists")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
