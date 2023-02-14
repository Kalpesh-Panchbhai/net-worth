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
    
    @StateObject var watchViewModel = WatchViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Text("All Watchlists")
                    .bold()
                    .foregroundColor(.white)
                    .font(.system(size: 15))
                Spacer()
                if(!(watchList.id?.isEmpty ?? false)) {
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
                HStack {
                    List {
                        ForEach(watchList.accountID, id: \.self) { accountId in
                            Text("accountId")
                        }
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
                            
                        }, label: {
                            Label("Add Account", systemImage: "")
                        })
                    }
                    .padding()
                }
            }
        }
        .halfSheet(showSheet: $newWatchListViewOpen) {
            NewWatchView(watchViewModel: watchViewModel)
        }
        .halfSheet(showSheet: $updateWatchListViewOpen) {
            UpdateWatchView(watchList: watchList, watchViewModel: watchViewModel)
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
