//
//  WatchListView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct WatchListView: View {
    
    init(){
        UISegmentedControl.appearance().selectedSegmentTintColor = .systemBlue
    }
    
    @State private var watchList = Watch()
    @State private var newWatchListViewOpen = false
    @State private var updateWatchListViewOpen = false
    @State private var addAccountViewOpen = false
    
    @StateObject var watchViewModel = WatchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("All Watchlists")
                        .bold()
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                    Spacer()
                    if(!(watchList.id?.isEmpty ?? false) && watchViewModel.watchList.count > 1) {
                        Button(action: {
                            WatchController().deleteWatchList(watchList: watchList)
                            Task.init {
                                await watchViewModel.getAllWatchList()
                                if(!watchViewModel.watchList.isEmpty) {
                                    watchList = watchViewModel.watchList[0]
                                } else {
                                    watchList = Watch()
                                }
                            }
                        }, label: {
                            Label("", systemImage: "trash")
                        }).foregroundColor(.red)
                    }
                    
                    if(watchViewModel.watchList.count > 3) {
                        NavigationLink(destination: {
                            AllWatchListView(watchViewModel: watchViewModel)
                        }, label: {
                            Label("See all", systemImage: "")
                        })
                    }
                    
                    Button(action: {
                        self.newWatchListViewOpen.toggle()
                    }, label: {
                        Label("", systemImage: "plus")
                    })
                }
                .padding()
                Picker("", selection: $watchList) {
                    ForEach(watchViewModel.watchList, id: \.self) { data in
                        Text(data.accountName).tag(data)
                    }
                }
                .pickerStyle(.segmented)
                
                VStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            ForEach(watchList.accountID, id: \.self) { account in
                                AccountRowView(account: Account(id: account))
                                    .shadow(color: Color.gray, radius: 3)
                            }
                            .padding(10)
                        }
                    }
                    if(!(watchList.id?.isEmpty ?? false)) {
                        HStack {
                            Button(action: {
                                self.updateWatchListViewOpen.toggle()
                                if(!watchViewModel.watchList.isEmpty) {
                                    watchList = watchViewModel.watchList[0]
                                }
                            }, label: {
                                Label("Edit WatchList", systemImage: "")
                            })
                            Spacer()
                            Button(action: {
                                self.addAccountViewOpen.toggle()
                            }, label: {
                                Label("Add Accounts", systemImage: "")
                            })
                        }
                        .padding()
                    }
                }
            }
        }
        .halfSheet(showSheet: $newWatchListViewOpen) {
            NewWatchView(watchViewModel: watchViewModel)
        }
        .halfSheet(showSheet: $updateWatchListViewOpen) {
            UpdateWatchView(watchList: watchList, watchViewModel: watchViewModel)
        }
        .sheet(isPresented: $addAccountViewOpen, onDismiss: {
            Task.init {
                await watchViewModel.getAllWatchList()
                if(!watchViewModel.watchList.isEmpty) {
                    watchList = watchViewModel.watchList.filter { item in
                        item.id == watchList.id
                    }.first!
                }
            }
        }) {
            AddAccountWatchListView(watch: watchList)
        }
        .onAppear {
            Task.init {
                await watchViewModel.getAllWatchList()
                if(!watchViewModel.watchList.isEmpty) {
                    watchList = watchViewModel.watchList[0]
                }
            }
        }
    }
}
