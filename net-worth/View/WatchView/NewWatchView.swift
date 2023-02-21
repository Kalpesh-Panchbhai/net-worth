//
//  NewWatchView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/02/23.
//

import SwiftUI

struct NewWatchView: View {
    
    @State private var watchListName = ""
    @State private var isFieldEmpty = false
    
    @Environment(\.dismiss) var dismiss
    
    var watchController = WatchController()
    
    @ObservedObject var watchViewModel: WatchViewModel
    
    var body: some View {
        VStack {
            Form {
                Section("New Watch List") {
                    TextField("Watch List name", text: $watchListName)
                }
            }
            VStack {
                Text("Submit")
            }.frame(width: 350, height: 50)
                .foregroundColor(.white)
                .background(.green)
                .bold()
                .cornerRadius(10)
                .onTapGesture {
                    if(watchListName.isEmpty) {
                        isFieldEmpty.toggle()
                    } else {
                        var watch = Watch()
                        watch.accountName = watchListName
                        watchController.addWatchList(watchList: watch)
                        Task.init {
                            await watchViewModel.getAllWatchList()
                        }
                        dismiss()
                    }
                }
            Spacer()
        }
        .alert(isPresented: $isFieldEmpty) {
            Alert(title: Text("Watch List Name cannot be empty"))
        }
    }
}