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
    @State var isPresentingWatchDeleteConfirm = false
    @State var selectedWatch = Watch()
    
    @EnvironmentObject var watchViewModel: WatchViewModel
    @EnvironmentObject var accountViewModel: AccountViewModel
    
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
                                WatchDetailView(watch: watch)
                                    .toolbarRole(.editor)
                            }, label: {
                                WatchViewRow(watch: watch)
//                                    .badge(
//                                        Text("\(watch.accountList.count)")
//                                            .foregroundColor(Color.theme.secondaryText)
//                                            .font(.caption.italic())
//                                    )
                            })
                            // MARK: Update
                            .swipeActions(edge: .leading, content: {
                                if(!watch.name.elementsEqual("All")) {
                                    Button("Update") {
                                        self.selectedWatch = watch
                                        self.updateWatchViewOpen = true
                                    }
                                    .tint(Color.theme.green)
                                }
                            })
                            .sheet(isPresented: $updateWatchViewOpen) {
                                UpdateWatchView(watch: selectedWatch)
                                    .presentationDetents([.medium])
                            }
                            // MARK: Delete
                            .swipeActions(edge: .trailing, content: {
                                if(!watch.name.elementsEqual("All")) {
                                    Button("Delete") {
                                        self.isPresentingWatchDeleteConfirm = true
                                        self.selectedWatch = watch
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
                    .confirmationDialog("Are you sure?",
                                        isPresented: $isPresentingWatchDeleteConfirm) {
                        Button("Delete account " + selectedWatch.name + "?", role: .destructive) {
                            Task.init {
                                await watchController.deleteWatchList(watch: selectedWatch)
                                await watchViewModel.getAllWatchList()
                            }
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
                        ZStack {
                            Circle()
                                .frame(width: 25, height: 25)
                                .foregroundColor(ColorTheme().green)
                            Image(systemName: ConstantUtils.plusImageName)
                                .foregroundColor(Color.theme.background)
                                .font(.system(size: 12))
                        }
                    })
                    .font(.system(size: 14))
                })
            }
            // MARK: New Watch Sheet View
            .sheet(isPresented: $newWatchListViewOpen) {
                NewWatchView()
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
